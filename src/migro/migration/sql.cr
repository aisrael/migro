struct Migro::Migration::Sql < Migro::Migration::Change
  getter :sql
  def initialize(@sql : String)
  end
  def execute(database : CQL::Database)
    database.exec(@sql)
  end
end
