require "../../spec_helper"
require "../../../src/migro/migration"

describe Migro::Migration::SqlMigration do
  it "can parse micrate-style SQL properly" do
    raw = <<-RAW
    -- +micrate Up
    -- SQL in section 'Up' is executed when this migration is applied
    CREATE TABLE foo;

    -- +micrate Down
    -- SQL section 'Down' is executed when this migration is rolled back
    DROP TABLE foo;
    RAW

    digest = Digest::MD5.new
    digest.update(raw)
    digest.final
    checksum = digest.result.to_slice.hexstring

    pp checksum

    filename = "1.sql"
    migration_file = Migro::MigrationFile.new(filename)

    migration = Migro::Migration::SqlMigration.new(migration_file, filename, checksum, raw)
    migration.up.size.should eq(1)
    migration.down.size.should eq(1)
  end
end
