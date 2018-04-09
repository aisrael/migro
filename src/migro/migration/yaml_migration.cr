struct Migro::Migration::YamlMigration < Migro::Migration
  getter :yaml

  private def all_as_h(array : Array(YAML::Type)) : Array(Hash(YAML::Type, YAML::Type))
    array.map do |e|
      raise "Expecting Hash(YAML::Type, YAML::Type), got #{e.class}!" unless e.is_a?(Hash(YAML::Type, YAML::Type))
      e
    end
  end

  def initialize(migration_file : MigrationFile, filename : String, checksum : String, @yaml : YAML::Any)
    super(migration_file, filename, checksum)
    unless @yaml.raw.nil?
      if @yaml.raw.is_a?(Hash(YAML::Type, YAML::Type))
        parse_yaml(@yaml.as_h)
      end
    end
  end

  def parse_yaml(hash)
    if hash.has_key?("metadata")
      if @yaml["metadata"]["version"]?
        version = @yaml["metadata"]["version"].as_s
      end
    end
    if hash.has_key?("changes")
      @changes += parse_changes(@yaml["changes"])
    end
    if hash.has_key?("up")
      @up += parse_changes(@yaml["up"])
    end
  end

  def parse_changes(changes)
    result = [] of Change
    changes.each do |change|
      change_as_h = change.as_h
      if change_as_h.has_key?("create_table")
        table = CQL::Table.from_yaml(change["create_table"])
        result << CreateTable.new(table)
      elsif change_as_h.has_key?("sql")
        sql = change["sql"].as_s
        result << Sql.new(sql)
      elsif change_as_h.has_key?("insert")
        insert = change["insert"]
        h = change["insert"].as_h
        raise "insert: has no table: name specified!" unless h.has_key?("table")
        table_name = insert["table"].as_s
        insert_rows = InsertRows.new
        if h.has_key?("rows")
          insert["rows"].each do |row|
            if row.raw.is_a?(Hash(YAML::Type, YAML::Type))
              keys = row.as_h.keys.map(&.to_s)
              insert_row = InsertRow.new
              keys.each do |key|
                case value = row[key].raw
                when SQLType
                  insert_row[key] = value
                else
                  raise "insert: Don't know how to handle value of type #{value.class}!"
                end
              end
              insert_rows << insert_row
            else
              raise "insert: Don't know how to handle row of type #{row.class}!"
            end
          end
        end
        result << Insert.new(table_name, insert_rows)
      end
    end
    result
  end

  def self.load_from_file(migration_file : MigrationFile, full_path_to_file : String) : Result(Migration)
    unless File.exists?(full_path_to_file) && File.file?(full_path_to_file) && File.readable?(full_path_to_file)
      return Result(Migration).failure(%(File "#{full_path_to_file}" does not exist or cannot be read!))
    end
    File.open(full_path_to_file) do |f|
      dio = DigestIO.md5(f)
      yaml = YAML.parse(dio)
      checksum = dio.hexdigest
      Result.success(YamlMigration.new(migration_file, full_path_to_file, checksum, yaml).as(Migration))
    end
  rescue e : IO::Error
    Result(Migration).failure(e.message || e.class.to_s)
  end

  def filename
    @migration_file.filename
  end
end
