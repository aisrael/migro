struct Migro::Migration::CreateTable < Migro::Migration::Change
  getter :table
  def initialize(@table : CQL::Table)
  end
  def up(database : CQL::Database)
    database.create_table(@table).exec
  end
  def down(database : CQL::Database)
    database.drop_table(@table).exec
  end
end
