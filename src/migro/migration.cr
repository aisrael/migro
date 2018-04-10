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

  def up(database : CQL::Database)
    changes.each do |change|
      change.up(database)
    end
    up.each do |change|
      change.up(database)
    end
  end

  def down(database : CQL::Database)
    changes.each do |change|
      change.down(database)
    end
    down.each do |change|
      change.down(database)
    end
  end

  abstract struct Change
    abstract def up(database : CQL::Database)
    abstract def down(database : CQL::Database)
  end

  alias SQLType = String | Char | Int8 | Int32 | Int64
  alias InsertRow = Hash(String | Symbol, SQLType)
  alias InsertRows = Array(InsertRow)

  def self.load_from_file(migration_file : MigrationFile, full_path_to_file : String) : Result(Migration)
    unless File.exists?(full_path_to_file) && File.file?(full_path_to_file) && File.readable?(full_path_to_file)
      return Result(Migration).failure(%(File "#{full_path_to_file}" does not exist or cannot be read!))
    end
    extension = migration_file.extension ? migration_file.extension.not_nil!.downcase : ""
    case extension
    when "sql"
      SqlMigration.load_from_file(migration_file, full_path_to_file)
    when "yaml", "yml"
      YamlMigration.load_from_file(migration_file, full_path_to_file)
    else
      return Result(Migration).failure(%(Don't know how to handle file of type "#{extension}"!))
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

require "./migration/*"
