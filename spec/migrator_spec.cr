require "./spec_helper"
require "../src/migro/migrator"

describe Migro::Migrator do
  it "can scan for migrations" do
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/migrations")
    migrator.migration_files.empty?.should be_false
    migrations = migrator.migrations
    migrations.empty?.should be_false
    migrations.size.should eq(8)
    migrations[0].filename.should eq("a.yml")
    migrations[1].filename.should eq("b.yml")
    migrations[2].filename.should eq("c.sql")
    migrations[3].filename.should eq("0-a.yml")
    migrations[4].filename.should eq("0-b.yml")
    migrations[5].filename.should eq("0-c.sql")
    migrations[6].filename.should eq("001.sql")
    migrations[7].filename.should eq("20180215153410-seed.yml")
  end

  it "can handle a single SQL migration up" do
    recreate_database
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/scenarios/single_sql_migration")
    migrator.migration_files.empty?.should be_false
    migrations = migrator.migrations
    migrations.empty?.should be_false
    migrations.size.should eq(1)
    migrations[0].filename.should eq("1.sql")
    migrator.up
    db = CQL.connect(DATABASE_URL)
    db.table_exists?("foo").should be_true
  end

  describe "migrations_log" do
    it "is an array of Migro::MigrationLog" do
      recreate_database
      migrator = Migro::Migrator.new(DATABASE_URL)
      migrator.logs
      log = migrator.migrations_log
      log.should be_a(Array(Migro::MigrationLog))
    end
  end
end
