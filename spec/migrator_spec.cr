require "./spec_helper"
require "../src/migro/migrator"

describe Migro::Migrator do
  it "can scan for migrations" do
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/migrations")
    begin
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
    ensure
      migrator.close_database
    end
  end

  it "can handle a single SQL migration up" do
    recreate_database
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/scenarios/single_sql_migration")
    db = CQL.connect(DATABASE_URL)
    begin
      migrator.migration_files.empty?.should be_false
      migrations = migrator.migrations
      migrations.empty?.should be_false
      migrations.size.should eq(1)
      migrations[0].filename.should eq("1.sql")
      migrator.up
      db.table_exists?("foo").should be_true
    ensure
      db.close
      migrator.close_database
    end
  end

  it "can do a single SQL migration up and down" do
    recreate_database
    migrator = Migro::Migrator.new(DATABASE_URL, migrations_dir: "test/fixtures/scenarios/single_sql_migration")
    db = CQL.connect(DATABASE_URL)
    begin
      migrator.up
      db.table_exists?("foo").should be_true
      db.count(Migro::Migrator::MIGRATIONS_LOG_TABLE).as_i64.should eq(1)
      migrator.down(1)
      db.table_exists?("foo").should be_false
      db.count(Migro::Migrator::MIGRATIONS_LOG_TABLE).as_i64.should eq(0)
    ensure
      db.close
      migrator.close_database
    end
  end

  describe "migrations_log" do
    it "is an array of Migro::MigrationLog" do
      # recreate_database
      migrator = Migro::Migrator.new(DATABASE_URL)
      begin
        migrator.logs
        log = migrator.migrations_log
        log.should be_a(Array(Migro::MigrationLog))
      ensure
        migrator.close_database
      end
    end
  end
end
