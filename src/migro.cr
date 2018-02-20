require "./migro/*"

unless ENV.has_key?("DATABASE_URL")
  STDERR.puts "$DATABASE_URL not defined"
  exit 1
end

DATABASE_URL = ENV["DATABASE_URL"]

migrator = Migro::Migrator.new DATABASE_URL
migrator.execute
