struct Migro::Migration::Sql < Migro::Migration::Change
  getter :sql
  def initialize(@sql : String)
  end
  def execute(database : CQL::Database)
    pp @sql
    exec_result = database.exec(@sql)
    pp exec_result
  end
end
