require "./spec_helper"
require "../src/migro/migration_file"

describe Migro::MigrationFile do
  describe ".new" do
    it "parses the filename into constituent parts" do
      mf = Migro::MigrationFile.new("20160524162446_add_users_table.sql")
      mf.numeric_prefix.should eq("20160524162446")
      mf.text.should eq("add_users_table")
      mf.extension.should eq("sql")
    end
    it "supports dash as the numeric prefix separator" do
      mf = Migro::MigrationFile.new("20160524162446-add_users_table.sql")
      mf.numeric_prefix.should eq("20160524162446")
      mf.text.should eq("add_users_table")
      mf.extension.should eq("sql")
    end
    it "can handle filenames with no text part" do
      mf = Migro::MigrationFile.new("001.sql")
      mf.numeric_prefix.should eq("001")
      mf.text.should be_nil
      mf.extension.should eq("sql")
    end
    it "can handle filenames with no numeric prefix" do
      mf = Migro::MigrationFile.new("add_users_table.sql")
      mf.numeric_prefix.should be_nil
      mf.text.should eq("add_users_table")
      mf.extension.should eq("sql")
    end
  end
  describe "#<=>" do
    it "compares by numeric prefix first" do
      a = Migro::MigrationFile.new("1_foo.yml")
      b = Migro::MigrationFile.new("2_foo.yml")
      c = Migro::MigrationFile.new("1_foo.yml")
      a.<=>(b).should eq(-1)
      b.<=>(a).should eq(1)
      a.<=>(c).should eq(0)
      c.<=>(a).should eq(0)
    end
    it "treats numeric prefixes as numbers first, then strings" do
      a = Migro::MigrationFile.new("1_foo.yml")
      b = Migro::MigrationFile.new("002_foo.yml")
      c = Migro::MigrationFile.new("001_foo.yml")
      a.<=>(b).should eq(-1)
      b.<=>(a).should eq(1)
      a.<=>(c).should eq(1)
      c.<=>(a).should eq(-1)
    end
    it "compares by text next" do
      a = Migro::MigrationFile.new("1_abc.yml")
      b = Migro::MigrationFile.new("1_def.yml")
      c = Migro::MigrationFile.new("1_abc.yml")
      a.<=>(b).should eq(-1)
      b.<=>(a).should eq(1)
      a.<=>(c).should eq(0)
      c.<=>(a).should eq(0)
    end
    it "treats no numeric prefix as if 0" do
      a = Migro::MigrationFile.new("foo.yml")
      b = Migro::MigrationFile.new("1_foo.yml")
      a.<=>(b).should eq(-1)
      b.<=>(a).should eq(1)
    end
    it "ignores file extensions" do
      a = Migro::MigrationFile.new("1_foo.yml")
      b = Migro::MigrationFile.new("2_foo.sql")
      c = Migro::MigrationFile.new("1_foo.yml")
      a.<=>(b).should eq(-1)
      b.<=>(a).should eq(1)
      a.<=>(c).should eq(0)
      c.<=>(a).should eq(0)
    end
    it "mixes & matches" do
      a = Migro::MigrationFile.new("001.sql")
      b = Migro::MigrationFile.new("a.yml")
      a.<=>(b).should eq(1)
      b.<=>(a).should eq(-1)
    end
  end
end
