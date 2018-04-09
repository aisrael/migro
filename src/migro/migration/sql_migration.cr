struct Migro::Migration::SqlMigration < Migro::Migration
  getter :raw
  getter :up
  getter :down

  def initialize(migration_file : MigrationFile, filename : String, checksum : String, @raw : String)
    super(migration_file, filename, checksum)
    parse_raw(@raw)
  end

  MICRATE_PREFIX = "-- +micrate"

  def parse_raw(raw : String)
    in_section = nil
    section = [] of String

    raw.each_line do |line|
      if line.starts_with?(MICRATE_PREFIX)
        if in_section
          case in_section
          when :up
            up << Migro::Migration::Sql.new(section.join("\n"))
          when :down
            down << Migro::Migration::Sql.new(section.join("\n"))
          end
          in_section = nil
        end

        cmd = line[MICRATE_PREFIX.size..-1].strip.downcase
        case cmd
        when "up"
          in_section = :up
        when "down"
          in_section = :down
        end
      elsif in_section
        section << line
      end
    end
    if in_section
      case in_section
      when :up
        up << Migro::Migration::Sql.new(section.join("\n"))
      when :down
        down << Migro::Migration::Sql.new(section.join("\n"))
      end
    end
  end

  def self.load_from_file(migration_file : MigrationFile, full_path_to_file : String) : Result(Migration)
    unless File.exists?(full_path_to_file) && File.file?(full_path_to_file) && File.readable?(full_path_to_file)
      return Result(Migration).failure(%(File "#{full_path_to_file}" does not exist or cannot be read!))
    end
    File.open(full_path_to_file) do |f|
      dio = DigestIO.md5(f)
      raw = f.gets_to_end
      checksum = dio.hexdigest
      Result.success(SqlMigration.new(migration_file, full_path_to_file, checksum, raw).as(Migration))
    end
  rescue e : IO::Error
    Result(Migration).failure(e.message || e.class.to_s)
  end

  def filename
    @migration_file.filename
  end
end
