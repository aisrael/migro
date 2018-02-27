# migrō

_(Latin) migrate_

A relational database migration tool, written in Crystal. It uses the [cql](https://github.com/aisrael/cql) framework.

## Migrations

`migro` currently only supports YAML migrations of the form

```yaml
metadata:
  version: 0.1
changes:
  - # ...
up:
  - # ...	
```

The `metadata.version` is optional, but if present, then `migro` will validate that it supports the given YAML migration version (currently, only `0.1` is allowed).

Both `changes:` and `up:` are arrays of [Migration Commands](#migration-commands).

`changes:` are meant to hold migration commands that can be automatically rolled back. Currently, only [`create_table`](#create-table) is allowed.

`up:` are meant to hold migration commands that will only be applied when migrating 'up' or forward.

TODO:

* [ ] Automatic rollback for commands in `changes:`
* [ ] Support `down:` changes

### Migration Commands

`migro` currently only supports three migration commands:

* `create_table`
* `insert`
* `sql`

#### Create Table

A `create_table` command takes the form:

```yaml
  - create_table:
    name: table_name
    columns:
    - # ...
```

Where each column has the following fields:

|field  |type    |remarks                                |
|-------|--------|---------------------------------------|
|name   |string  |required                               |
|type   |SQL type|required                               |
|size   |int     |applies to `CHAR` and `VARCHAR`, mainly|
|null   |boolean |whether `NULLABLE` or `NOT NULLABLE`   |
|primary|boolean |specifies the column is a `PRIMARY KEY`|

#### Insert

An `insert` command takes the form:

```yaml
  - insert:
      table: table_name
      rows:
      - column1: value
        column2: 123
```

Which is equivalent to the SQL:

```sql
INSERT INTO table_name (column1, column2)
VALUES ("value", 123);
```

#### SQL

A `sql` command takes in 'raw' SQL:

```yaml
  - sql:
      ALTER TABLE params
      ADD CONSTRAINT params_unique_code_and_name UNIQUE (code, name);
```

The given SQL is executed 'as is'.