struct Migro::Migration::CreateTable < Migro::Migration::Change
  getter :table
  def initialize(@table : CQL::Table)
  end
  def execute(database : CQL::Database)
    database.create_table(@table).exec
  end
end
