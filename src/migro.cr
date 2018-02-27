require "./migro/*"
require "./command"

class Main < Command::Main

  short_description "migrō - a database migration tool"
  version "0.2"

  flag "database-url",
        description: "Use the given database url. Defaults to $DATABASE_URL if not given",
        expects_value: true
  # command new: New, description: "Creates a new migration file"
  command up: Up, description: "Executes all new migrations going 'up'"
  command logs: Logs, description: "Displays the database migration log", alias: "log"

  class New < ::Command
    def run
      p args: args
      puts args.join("-")
    end
  end

  class Up < ::Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.up(db_url)
    end
  end

  class Logs < ::Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      p db_url: db_url
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.logs(db_url)
    end
  end
end

Main.run
