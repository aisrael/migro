# migrō

[![Join the chat at https://gitter.im/migro-io/migro](https://badges.gitter.im/migro-io/migro.svg)](https://gitter.im/migro-io/migro?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
 
_(Latin) migrate_

A relational database migration tool, written in Crystal.

## Installation

Requirements:

* [Crystal](https://crystal-lang.org/) (currently built & tested using 0.24.1)

##### Clone this repository

```
git clone https://github.com/aisrael/migro.git
```

##### Build the executable and place it in your $PATH

```
shards build --release
```

That will build `bin/migro`. Copy that file anywhere in your $PATH

## Usage

`migro` expects database migrations to be in `db/migrations` (relative to the current directory).

Migration files can be named using one of the following patterns:

* `text_only.yml` - text only, will be executed _before_ everything else (in alphabetical order)
* `001_some_text.yml`, `201802240803-some-text.yml` - numeric prefix plus text, will be executed in order of the numeric prefix first, then alphabetical order if same numeric prefix

### Migration files

`migro` currently only supports YAML migrations of the form

```
metadata:
  version: 0.1
changes:
  - create_table:
    name: users
    columns:
    - name: id
      type: SERIAL
      null: false
      primary: true
    - name: username
      type: VARCHAR
      size: 40
      null: false
    - name: password_hash
      type: CHAR
      size: 128
      null: false
up:
  - insert:
      table: users
      rows:
        - username: system
        - password_hash: b37e50cedcd3e3f1ff64f4afc0422084ae694253cf399326868e07a35f4a45fb
```

Which is equivalent to running the following SQL commands:

```
CREATE TABLE users (id SERIAL NOT NULL PRIMARY KEY, username VARCHAR(40) NOT NULL, password_hash CHAR(128) NOT NULL);
INSERT INTO users (username, password) VALUES ('system', 'b37e50cedcd3e3f1ff64f4afc0422084ae694253cf399326868e07a35f4a45fb');
```

## Development

TODO:

* [ ] Support for `.sql` migrations ala `micrate`
* [ ] Improved CLI, e.g. `migro up`, `migro down`, `migro rollback --to 042-some.yml`

## Contributing

1. Fork it ( https://github.com/aisrael/migro/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [aisrael](https://github.com/aisrael) Alistair A. Israel - creator, maintainer
