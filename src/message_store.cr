require "db"
require "pg"
require "uuid"
require "./message_store/*"

module MessageStore
  VERSION = "0.1.0"

  class MessageStore
    include Config
    include PostgresStore

    def write(event : Event, stream : String)
      payload = event.to_json
      metadata = event.metadata.to_json
      stream_data = parse_stream stream
      event_name = event.class.name

      write_message event_name, payload, metadata, stream_data[:name], stream_data[:category], stream_data[:id]
      notification = {
        event_name: event_name,
        payload: payload,
        metadata: metadata
      }
      notify(stream, notification.to_json)
    end

    def fetch_entity(stream : String)
    end

    def subscribe(stream : String, handler : Handler)
      spawn
    end

    def notify(stream : String, payload : String)
      with_db { |db| db.exec("SELECT pg_notify($1, $2)", stream, payload) }
    end

    private def write_message(
      event_type : String,
      payload : String,
      metadata : String,
      stream_name : String,
      stream_category : String?,
      stream_id : String?
    ) : String
      with_db do |db|
        latest_id = latest_position db, stream_name, stream_category, stream_id

        id = UUID.random.to_s
        db.exec(
          insert_message_stmt,
          id,
          stream_name, stream_category, stream_id,
          event_type,
          latest_id.nil? ? 1 : latest_id + 1,
          payload, metadata,
        )

        id
      end
    end

    private def parse_stream(stream : String)
      match = stream.match /^(.+?)(\:(.+?))?(\/(.+?))?$/

      raise "Invalid stream name [#{stream}]" if match.nil?

      name = match[1]
      category = match[3]?
      id = match[5]?

      {name: name, category: category, id: id}
    end

    private def latest_position_params(stream_name : String, stream_category : Nil, stream_id : Nil)
      {stream_name}
    end

    private def latest_position_params(stream_name : String, stream_category : String, stream_id : Nil)
      {stream_name, stream_category}
    end

    private def latest_position_params(stream_name : String, stream_category : Nil, stream_id : String)
      {stream_name, stream_id}
    end

    private def latest_position_params(stream_name : String, stream_category : String, stream_id : String)
      {stream_name, stream_category, stream_id}
    end

    private def latest_position(db : DB::Database, stream_name : String, stream_category : String?, stream_id : String?)
      query = latest_position_query stream_name, stream_category, stream_id
      fetch_latest_position(db, query, stream_name, stream_category, stream_id)
    end

    private def fetch_latest_position(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : String)
      db.query_one(query, stream_name, stream_category, stream_id, as: {Int64 | Nil})
    end

    private def fetch_latest_position(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : Nil)
      db.query_one(query, stream_name, as: {Int64 | Nil})
    end

    private def fetch_latest_position(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : String)
      db.query_one(query, stream_name, stream_id, as: {Int64 | Nil})
    end

    private def fetch_latest_position(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : Nil)
      db.query_one(query, stream_name, stream_category, as: {Int64 | Nil})
    end

    private def latest_position_query(stream_name : String, stream_category : String?, stream_id : String?)
      pidx = 1
      stream_category_criteria = stream_category.nil? ? "IS NULL" : "= $#{pidx += 1}"
      stream_id_criteria = stream_id.nil? ? "IS NULL" : "= $#{pidx += 1}"

      query = <<-SQL
        SELECT
          max(position)
        FROM
          #{config.messages_table}
        WHERE
          stream_name = $1
          AND stream_category #{stream_category_criteria}
          AND stream_id  #{stream_id_criteria}
      SQL
    end

    private def insert_message_stmt
      <<-SQL
        INSERT INTO
          #{config.messages_table}
            (id, stream_name, stream_category, stream_id, type, position, data, metadata)
          VALUES
            ($1, $2, $3, $4, $5, $6, $7, $8);
      SQL
    end
  end
end
