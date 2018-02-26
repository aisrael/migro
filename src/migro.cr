require "./migro/*"
require "./command"

class Main < Command

  version "0.2"
  short_description "migrō - a database migration tool"

  flag "database-url",
       description: "Use the given database url. Defaults to $DATABASE_URL if not given",
       expects_value: true

  class New < Command
    def run
      puts args.join("-")
    end
  end

  class Up < Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.up(db_url)
    end
  end

  class Logs < Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.logs(db_url)
    end
  end

  command :new, New, "Creates a new migration file"
  command :up, Up, "Executes all new migrations going 'up'"
  command :logs, Logs, "Displays the database migration log"

  def run
  end
end

Main.run
