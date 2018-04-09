struct Migro::Migration::SqlMigration < Migro::Migration
  getter :raw
  getter :up
  getter :down

  def initialize(migration_file : MigrationFile, filename : String, checksum : String, @raw : String)
    super(migration_file, filename, checksum)
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
