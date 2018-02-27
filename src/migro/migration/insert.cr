struct Migro::Migration::Insert < Migro::Migration::Change
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
