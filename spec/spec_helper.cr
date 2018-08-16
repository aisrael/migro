require "spec"
require "pg"

# Recreate migro_test database and execute migrations

unless ENV.has_key?("DATABASE_URL")
  STDERR.puts "$DATABASE_URL not defined"
  exit 1
end

DATABASE_URL = ENV["DATABASE_URL"]

def recreate_database
  unless path = URI.parse(DATABASE_URL).path
    STDERR.puts %(Cannot parse path component of "#{DATABASE_URL}"!)
    exit 1
  end

  database_name = path.starts_with?("/") ? path[1..-1] : path
  url_without_path = DATABASE_URL[0..-path.size - 1]

  # TODO MySQL?
  DB.open(url_without_path) do |db|
    puts "DROP DATABASE IF EXISTS #{database_name};"
    db.exec("DROP DATABASE IF EXISTS #{database_name};")
    puts "CREATE DATABASE #{database_name};"
    db.exec("CREATE DATABASE #{database_name};")
  end
end

recreate_database
