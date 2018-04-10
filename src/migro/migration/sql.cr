struct Migro::Migration::Sql < Migro::Migration::Change
  getter :up, :down
  def initialize(@up : String?, @down : String?)
  end
  def up(database : CQL::Database)
    raise "This SQL change only goes down!" unless up = @up
    database.exec(up)
  end
  def down(database : CQL::Database)
    raise "This SQL change only goes up!" unless down = @down
    pp down
    database.exec(down)
  end
end
