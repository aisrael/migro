require "digest/md5"
require "../result"
require "./migration_file"
require "../digest_io"

struct Migro::Migration
  getter :metadata
  getter :logger
  getter :migration_file
  getter :filename
  getter :checksum
  getter :yaml
  getter :changes
  getter :up

  @metadata : NamedTuple(version: String)
  @changes : Array(Hash(YAML::Type, YAML::Type))
  @up : Array(Hash(YAML::Type, YAML::Type))

  private def all_as_h(array : Array(YAML::Type)) : Array(Hash(YAML::Type, YAML::Type))
    array.map do |e|
      raise "Expecting Hash(YAML::Type, YAML::Type), got #{e.class}!" unless e.is_a?(Hash(YAML::Type, YAML::Type))
      e
    end
  end

  def initialize(@logger : Logger, @migration_file : MigrationFile, @checksum : String, @yaml : YAML::Any)
    version = "0.1"
    changes = [] of Hash(YAML::Type, YAML::Type)
    up = [] of Hash(YAML::Type, YAML::Type)
    unless @yaml.raw.nil?
      if @yaml.raw.is_a?(Hash(YAML::Type, YAML::Type))
        hash = @yaml.as_h
        if hash.has_key?("metadata")
          if @yaml["metadata"]["version"]?
            version = @yaml["metadata"]["version"].as_s
          end
        end
        if hash.has_key?("changes")
          changes = all_as_h(@yaml["changes"].as_a)
        end
        if hash.has_key?("up")
          up = all_as_h(@yaml["up"].as_a)
        end
      end
    end
    @metadata = {version: version}
    @changes = changes
    @up = up
  end

  def self.load_from_file(logger : Logger, migration_file : MigrationFile, filename : String) : Result(Migration)
    unless File.exists?(filename) && File.file?(filename) && File.readable?(filename)
      return Result(Migration).failure(%(File "#{filename}" does not exist or cannot be read!))
    end
    File.open(filename) do |f|
      dio = DigestIO.md5(f)
      yaml = YAML.parse(dio)
      checksum = dio.hexdigest
      Result.success(Migration.new(logger, migration_file, checksum, yaml))
    end
  rescue e : IO::Error
    Result(Migration).failure(e.message || e.class.to_s)
  end

  def filename
    @migration_file.filename
  end
end

# A simple struct to hold the database migration log records
struct Migro::MigrationLog
  getter :timestamp, :filename, :checksum
  def initialize(@timestamp : Time, @filename : String, @checksum : String)
  end
end
