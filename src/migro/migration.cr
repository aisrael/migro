require "digest/md5"
require "logging"
require "../result"
require "./migration_file"
require "../digest_io"

abstract struct Migro::Migration
  include Logging

  @metadata : NamedTuple(version: String)
  @changes = [] of Change
  @up = [] of Change
  @down = [] of Change

  getter :migration_file, :metadata, :filename, :checksum
  getter :changes, :up, :down

  def initialize(@migration_file : MigrationFile, @filename : String, @checksum : String)
    version = "0.1"
    @metadata = {version: version}
  end

  abstract struct Change
    abstract def execute(database : CQL::Database)
  end

  struct CreateTable < Change
    getter :table
    def initialize(@table : CQL::Table)
    end
    def execute(database : CQL::Database)
      database.create_table(@table).exec
    end
  end

  alias SQLType = String | Char | Int8 | Int32 | Int64
  alias InsertRow = Hash(String | Symbol, SQLType)
  alias InsertRows = Array(InsertRow)

  struct Insert < Change
    def initialize(@table_name : String, @rows : InsertRows)
    end
    def execute(database : CQL::Database)
      @rows.each do |row|
        column_names = row.keys.map(&.to_s)
        values = column_names.map {|key| row[key] }
        database.insert(@table_name).columns(column_names).exec(values)
      end
    end
  end

  @@known_extensions = {} of String => Migro::Migration.class
  class_getter :known_extensions

  def self.load_from_file(migration_file : MigrationFile, full_path_to_file : String) : Result(Migration)
    unless File.exists?(full_path_to_file) && File.file?(full_path_to_file) && File.readable?(full_path_to_file)
      return Result(Migration).failure(%(File "#{full_path_to_file}" does not exist or cannot be read!))
    end
    extension = migration_file.extension ? migration_file.extension.not_nil!.downcase : ""
    if @@known_extensions.has_key?(extension)
      @@known_extensions[extension].load_from_file(migration_file, full_path_to_file)
    else
      return Result(Migration).failure(%(Don't know how to handle file of type "#{migration_file.extension}"!))
    end
  rescue e : IO::Error
    Result(Migration).failure(e.message || e.class.to_s)
  end

end

# A simple struct to hold the database migration log records
struct Migro::MigrationLog
  getter :timestamp, :filename, :checksum
  def initialize(@timestamp : Time, @filename : String, @checksum : String)
  end
end

require "./migration/yaml_migration"
