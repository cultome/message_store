module MessageStore::Utils
  def latest_position(db : DB::Database, stream : String)
    query = select_on_stream_query "max(position)", stream
    rs = query_to_stream(db, query, stream)
    rs.move_next
    rs.read(Int64?)
  end

  def build_event(event_class : Event.class, data_payload : JSON::Any, metadata_payload : JSON::Any) : Event
    event_instance = event_class.from_json data_payload.to_json

    unless metadata_payload.nil?
      event_instance.metadata = Hash(String, String).from_json metadata_payload.to_json
    end

    event_instance
  end

  def build_event(event_class : Event.class, data_payload : String, metadata_payload : String) : Event
    event_instance = event_class.from_json data_payload

    unless metadata_payload.empty?
      event_instance.metadata = Hash(String, String).from_json(metadata_payload)
    end

    event_instance
  end

  def select_on_stream_query(select_clause : String, stream : String)
    pidx = 1
    stream_data = parse_stream stream
    stream_category_criteria = stream_data[:category].nil? ? "IS NULL" : "= $#{pidx += 1}"
    stream_id_criteria = stream_data[:id].nil? ? "IS NULL" : "= $#{pidx += 1}"

    query = <<-SQL
      SELECT
        #{select_clause}
      FROM
        #{config.messages_table}
      WHERE
        stream_name = $1
        AND stream_category #{stream_category_criteria}
        AND stream_id  #{stream_id_criteria}
    SQL
  end

  def classname_table(classes : Array(Object.class))
    classes.each_with_object(Hash(String, Event.class).new) { |clazz, acc| acc[clazz.name] = clazz }
  end

  private def query_to_stream(db : DB::Database, query : String, stream : String)
    stream_data = parse_stream stream

    query_to_stream(db, query, stream_data[:name], stream_data[:category], stream_data[:id])
  end

  private def query_to_stream(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : String)
    db.query(query, stream_name, stream_category, stream_id)
  end

  private def query_to_stream(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : Nil)
    db.query(query, stream_name)
  end

  private def query_to_stream(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : String)
    db.query(query, stream_name, stream_id)
  end

  private def query_to_stream(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : Nil)
    db.query(query, stream_name, stream_category)
  end

  private def parse_stream(stream : String)
    match = stream.match /^(.+?)(\:(.+?))?(\/(.+?))?$/

    raise "Invalid stream name [#{stream}]" if match.nil?

    name = match[1]
    category = match[3]?
    id = match[5]?

    {name: name, category: category, id: id}
  end
end
