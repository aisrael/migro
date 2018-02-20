require "./spec_helper"
require "../src/migro/migrator"

describe Migro::Migrator do
  it "can scan for migrations" do
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/migrations")
    migrator.migration_files.empty?.should be_false
    migrations = migrator.migrations
    migrations.empty?.should be_false
    migrations.size.should eq(5)
    migrations[0].filename.should eq("a.yml")
    migrations[1].filename.should eq("b.yml")
    migrations[2].filename.should eq("0-a.yml")
    migrations[3].filename.should eq("0-b.yml")
    migrations[4].filename.should eq("20180215153410-seed.yml")
  end

  describe "migrations_log" do
    it "is an array of Migro::MigrationLog" do
      migrator = Migro::Migrator.new(DATABASE_URL)
      log = migrator.migrations_log
      log.should be_a(Array(Migro::MigrationLog))
    end
  end
end
