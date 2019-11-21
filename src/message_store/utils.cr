module MessageStore::Utils
  def latest_position(db : DB::Database, stream : String) : Int64
    query = select_on_stream_query "max(position)", stream, ordered: false

    position = 0
    query_to_stream(db, query, stream) do |rs|
      val = rs.read(Int64?)
      position = val unless val.nil?
    end

    position.to_i64
  end

  def build_event(
    event_class : Event.class,
    id : String,
    stream_name : String,
    stream_category : String?,
    stream_id : String?,
    type : String,
    position : Int64,
    global_position : Int64,
    data_payload : JSON::Any,
    metadata_payload : JSON::Any,
    time : Time
  ) : Event
    instance = event_class.from_json data_payload.to_json

    instance.metadata = Hash(String, String).from_json(metadata_payload.to_json) unless metadata_payload.nil?

    instance.metadata = {
      "type" => event_class.name,
      "id" => id,
      "stream_name" => stream_name,
      "type" => type,
      "position" => position.to_s,
      "global_position" => global_position.to_s,
      "time" => time.to_s
    }
    instance.metadata["stream_category"] = stream_category unless stream_category.nil?
    instance.metadata["stream_id"] = stream_id unless stream_id.nil?

    instance
  end

  def build_event(event_class : Event.class, data_payload : String, metadata_payload : String) : Event
    event_instance = event_class.from_json data_payload

    unless metadata_payload.nil?
      event_instance.metadata = Hash(String, String).from_json(metadata_payload)
    end

    event_instance
  end

  def select_on_stream_query(select_clause : String, stream : String, where_clause : String? = nil, ordered : Bool = true)
    name, category, id = parse_stream stream

    pidx = 1
    stream_category_criteria = category.nil? ? "IS NULL" : "= $#{pidx += 1}"
    stream_id_criteria = id.nil? ? "IS NULL" : "= $#{pidx += 1}"

    query = <<-SQL
      SELECT
        #{select_clause}
      FROM
        #{config.messages_table}
      WHERE
        stream_name = $1
        AND stream_category #{stream_category_criteria}
        AND stream_id  #{stream_id_criteria}
        #{where_clause.nil? ? "" : "AND #{where_clause}"}
      #{ordered ? "ORDER BY position asc" : ""}
    SQL
  end

  def classname_table(classes : Array(Object.class))
    classes.each_with_object(Hash(String, Event.class).new) { |clazz, acc| acc[clazz.name] = clazz }
  end

  def query_to_stream(db : DB::Database, query : String, stream : String, &block : DB::ResultSet ->)
    name, category, id = parse_stream stream

    execute_query_on_stream(db, query, name, category, id) do |rs|
      rs.each { block.call rs }
    end
  end

  private def execute_query_on_stream(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : String, &block : DB::ResultSet ->)
    db.query(query, stream_name, stream_category, stream_id, &block)
  end

  private def execute_query_on_stream(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : Nil, &block : DB::ResultSet ->)
    db.query(query, stream_name, &block)
  end

  private def execute_query_on_stream(db : DB::Database, query : String, stream_name : String, stream_category : Nil, stream_id : String, &block : DB::ResultSet ->)
    db.query(query, stream_name, stream_id, &block)
  end

  private def execute_query_on_stream(db : DB::Database, query : String, stream_name : String, stream_category : String, stream_id : Nil, &block : DB::ResultSet ->)
    db.query(query, stream_name, stream_category, &block)
  end

  private def parse_stream(stream : String) : Tuple(String, String?, String?)
    match = stream.match /^(.+?)(\:(.+?))?(\/(.+?))?$/

    raise "Invalid stream name [#{stream}]" if match.nil?

    # name, category, id
    {match[1], match[3]?, match[5]?}
  end
end
