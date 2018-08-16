require "cql"
require "logging"
require "pg"
require "yaml"
require "./migration_file"
require "./migration"

Logging::Config.root_level = Logger::DEBUG

class Migro::Migrator
  include Logging

  getter :database_url
  getter :migrations_dir, :migrations_dir_full_path
  getter :migration_files

  getter :logger
  @migration_files : Array(MigrationFile)
  @migrations : Array(Migration)?

  DEFAULT_MIGRATIONS_DIR = File.join("db", "migrations")
  MIGRATIONS_LOG_TABLE   = "database_migrations_log"

  def initialize(@database_url : String, migrations_dir = DEFAULT_MIGRATIONS_DIR, logger = Logger.new(STDOUT))
    @migration_files_dir = migrations_dir
    @migration_files_dir_full_path = File.expand_path(@migration_files_dir)
    raise %(Path #{@migration_files_dir_full_path} is not a directory!) unless File.directory?(@migration_files_dir_full_path)
    raise %(Path #{@migration_files_dir_full_path} cannot be read!) unless File.readable?(@migration_files_dir_full_path)
    @migration_files = scan_for_migrations
    @database = CQL.connect(@database_url)
  end

  def close_database
    @database.close
  end

  {% for command in %w[up down logs] %}
    def self.{{command.id}}(database_url : String)
      self.new(database_url).{{command.id}}
    end
  {% end %}

  def up
    check_and_ensure_migrations_log_table_exists
    case result = verify_migration_log_integrity
    when Failure
      STDERR.puts result.message
      exit 1
    when Success
      execute_new_migrations
    end
  end

  def down(n = 1)
    check_and_ensure_migrations_log_table_exists
    case result = verify_migration_log_integrity
    when Failure
      STDERR.puts result.message
      exit 1
    when Success
      rollback(n)
    end
  end

  def logs
    check_and_ensure_migrations_log_table_exists
    case result = verify_migration_log_integrity
    when Failure
      STDERR.puts result.message
      exit 1
    when Success
      migrations_log.each do |log|
        puts "#{Time::Format::ISO_8601_DATE_TIME.format(log.timestamp)} #{log.filename}"
      end
    end
  end

  def scan_for_migrations
    Dir.children(@migration_files_dir_full_path).select do |name|
      /^(\d+-)?.+$/ =~ name
    end.map do |name|
      MigrationFile.new(name)
    end.sort
  end

  def migrations : Array(Migration)
    @migrations ||= load_migrations.not_nil!
  end

  @schema : CQL::Schema(MigrationLog)?

  def schema
    @schema ||= CQL::Schema.new(@database, MigrationLog, MIGRATIONS_LOG_TABLE,
      timestamp: Time,
      filename: String,
      checksum: String
    )
  end

  def migrations_log : Array(MigrationLog)
    return [] of MigrationLog unless migrations_log_table_exists?
    schema.all
  end

  private def load_migrations
    @migration_files.reduce([] of Migration) do |migrations, migration_file|
      full_path_to_file = File.join(@migration_files_dir_full_path, migration_file.filename)
      case result = Migration.load_from_file(migration_file, full_path_to_file)
      when Failure
        error(result.message)
      when Success
        migrations << result.value
      end
      migrations
    end
  end

  MIGRATIONS_LOG_TABLE_DEFINITION = CQL::Table.new(MIGRATIONS_LOG_TABLE).tap do |table|
    table.column "timestamp", CQL::TIMESTAMP, null: false, default: "NOW()"
    table.column "filename", CQL::VARCHAR, size: 120, null: false
    table.column "checksum", CQL::CHAR, size: 32, null: false
  end

  private def check_and_ensure_migrations_log_table_exists
    unless migrations_log_table_exists?
      @database.create_table(MIGRATIONS_LOG_TABLE_DEFINITION).exec
    end
  end

  private def migrations_log_table_exists?
    @database.table_exists?(MIGRATIONS_LOG_TABLE)
  end

  private def verify_migration_log_integrity : Result(Int32)
    logs = migrations_log
    n_log_entries = logs.size
    n_migrations = migrations.size
    if n_migrations < n_log_entries
      return Result(Int32).failure(%(Migrations log has #{n_log_entries} entries, but can only find #{n_migrations} migrations!))
    end
    (0...n_log_entries).each do |i|
      log = logs[i]
      file = migrations[i]
      if file.filename != log.filename
        return Result(Int32).failure(%(Missing migration file "#{log.filename}", cowardly refusing to proceed))
      end
      if file.checksum != log.checksum
        return Result(Int32).failure(%(Migration file "#{log.filename}" has changed (expected checksum #{log.checksum} != #{file.checksum}), cowardly refusing to proceed))
      end
    end
    Result.success(n_log_entries)
  end

  private def execute_new_migrations
    new_migrations = migrations[migrations_log.size..-1]
    if new_migrations.empty?
      puts "Database is up to date"
      return
    end
    new_migrations.each do |migration|
      migration.up(@database)
      record_into_log(migration)
    end
  end

  private def rollback(n : Int32)
    debug "rollback(#{n})"
    logs_to_rollback = migrations_log[migrations_log.size - n..-1]
    pp logs_to_rollback
    migrations_to_rollback = migrations[migrations_log.size - n..-1]
    pp migrations_to_rollback
    logs_and_migrations = logs_to_rollback.zip(migrations_to_rollback)
    logs_and_migrations.reverse.each do |log, migration|
      migration.down(@database)
      remove_from_log(log)
    end
  end

  private def remove_from_log(log)
    # Need to 'finesse' the timestamp serialization since crystal_pg encodes using ISO 8601
    # which doesn't match what PostgreSQL 'sees'
    timestamp_in_pg_format = log.timestamp.to_s("%Y-%m-%d %H:%M:%S.%6N")

    rows_affected = schema.where(
      timestamp: timestamp_in_pg_format,
      filename: log.filename,
      checksum: log.checksum).delete
    raise %(Expected 1 row deleted, got #{rows_affected}!) unless rows_affected == 1
  end

  private def record_into_log(migration)
    schema.insert("filename", "checksum").values(migration.filename, migration.checksum)
  end
end
