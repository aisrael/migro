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
  command :help do
    puts <<-HELP
    #{@@short_description}, version #{@@version}
    Usage:

      migro <command> [flags]

    Commands:
      up             - Executes all new migrations going 'up'
      logs           - Displays the database migration log
      help           - Prints this help text

    Flags:
      --database-url - Use the given database url. Defaults to $DATABASE_URL if not given
    HELP
  end
end

Main.run
