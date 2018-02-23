require "admiral"
require "./migro/*"
require "./command"

unless ENV.has_key?("DATABASE_URL")
  STDERR.puts "$DATABASE_URL not defined"
  exit 1
end

class Main < Command

  DATABASE_URL = ENV["DATABASE_URL"]
  MIGRATOR = Migro::Migrator.new(DATABASE_URL)

  version "0.2"
  short_description "migrō - a database migration tool"

  def run
  end

end

Main.run
