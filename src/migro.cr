require "./migro/*"
require "./command"

class Main < Command

  version "0.2"
  short_description "migrō - a database migration tool"

  flag "database-url", expects_value: true
  command :up do
    db_url = options["database-url"]? || ENV["DATABASE_URL"]?
    unless db_url
      STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
      exit 1
    end
    Migro::Migrator.up(db_url)
  end
  command :logs do
    db_url = options["database-url"]? || ENV["DATABASE_URL"]?
    unless db_url
      STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
      exit 1
    end
    Migro::Migrator.logs(db_url)
  end
end

Main.run
