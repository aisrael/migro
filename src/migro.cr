require "./migro/*"
require "./command"

class Main < Command

  version "0.2"
  short_description "migrō - a database migration tool"

  flag "database-url",
       description: "Use the given database url. Defaults to $DATABASE_URL if not given",
       expects_value: true
  command new: "Creates a new migration file" do |cmd|
    puts cmd.args.join("-")
  end
  command up: "Executes all new migrations going 'up'" do |cmd|
    db_url = cmd.options["database-url"]? || ENV["DATABASE_URL"]?
    unless db_url
      STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
      exit 1
    end
    Migro::Migrator.up(db_url)
  end
  command logs: "Displays the database migration log" do |cmd|
    db_url = cmd.options["database-url"]? || ENV["DATABASE_URL"]?
    unless db_url
      STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
      exit 1
    end
    Migro::Migrator.logs(db_url)
  end
end

Main.run
