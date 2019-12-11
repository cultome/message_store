# message_store

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     message_store:
       github: cultome/message_store
   ```

2. Run `shards install`

## Usage

```crystal
require "message_store"
```

```sql
CREATE TABLE IF NOT EXISTS "entity_snapshots" (
  "stream" text NOT NULL,
  "position" bigint NOT NULL,
  "type" text NOT NULL,
  "data" jsonb,
  "metadata" jsonb,
  "time" TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc') NOT NULL
)
```

```sql
CREATE TABLE IF NOT EXISTS "messages" (
  "id" UUID NOT NULL,
  "stream_name" text NOT NULL,
  "stream_category" text,
  "stream_id" text,
  "type" text NOT NULL,
  "position" bigint NOT NULL,
  "global_position" bigserial NOT NULL,
  "data" jsonb,
  "metadata" jsonb,
  "time" TIMESTAMP WITHOUT TIME ZONE DEFAULT (now() AT TIME ZONE 'utc') NOT NULL
)
```

## TODO

 * Initialize database easily

## Development

## Contributing

1. Fork it (<https://github.com/your-github-user/message_store/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Carlos Soria](https://github.com/your-github-user) - creator and maintainer
