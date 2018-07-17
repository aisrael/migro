require "./migro/version"
require "./migro/*"
require "./command"

class Main < Command::Main
  short_description "migrō - a database migration tool"
  version Migro::VERSION

  flag "database-url",
    description: "Use the given database url. Defaults to $DATABASE_URL if not given",
    expects_value: true
  command new: New, description: "Creates a new migration file"
  command up: Up, description: "Executes all new migrations"
  command down: Down, description: "Rollsback previous migrations"
  command logs: Logs, description: "Displays the database migration log", alias: "log"
  default_command :help

  class New < ::Command
    def run
      if args.empty?
        puts <<-USAGE
        Usage:
          migro new text
        USAGE
        exit 1
      end
      now = Time.now
      now_s = now.to_s("%Y%m%d%H%M%S")
      parts = args.map { |s| s.underscore.gsub(/\s+/, "_") }
      filename = "#{now_s}-#{parts.join("_")}.yml"
      full_path_to_file = File.join(Migro::Migrator::DEFAULT_MIGRATIONS_DIR, filename)
      if File.exists?(full_path_to_file)
        STDERR.puts "Migration file #{full_path_to_file} already exists!"
        exit 1
      end
      contents = <<-EOF
      ---
      metadata:
        version: 0.1
        description: #{args.join(" ")}
      changes:
        # Add YAML changes here
      EOF
      File.write(full_path_to_file, contents)
      puts "Created #{full_path_to_file}"
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

  class Down < ::Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.down(db_url)
    end
  end

  class Logs < ::Command
    def run
      db_url = options["database-url"]? || ENV["DATABASE_URL"]?
      unless db_url
        STDERR.puts "No --database-url flag given and no $DATABASE_URL environment variable defined!"
        exit 1
      end
      Migro::Migrator.logs(db_url)
    end
  end
end

Main.run
