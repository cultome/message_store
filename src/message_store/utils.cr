module MessageStore::Utils
  def latest_position(db : DB::Database, stream : String)
    stream_data = parse_stream stream
    query = latest_position_query stream_data[:name], stream_data[:category], stream_data[:id]
    fetch_latest_position(db, query, stream_data[:name], stream_data[:category], stream_data[:id])
  end

  def parse_stream(stream : String)
    match = stream.match /^(.+?)(\:(.+?))?(\/(.+?))?$/

    raise "Invalid stream name [#{stream}]" if match.nil?

    name = match[1]
    category = match[3]?
    id = match[5]?

    {name: name, category: category, id: id}
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

  private def stream_query(select_clause : String, stream_name : String, stream_category : String?, stream_id : String?)
    pidx = 1
    stream_category_criteria = stream_category.nil? ? "IS NULL" : "= $#{pidx += 1}"
    stream_id_criteria = stream_id.nil? ? "IS NULL" : "= $#{pidx += 1}"

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

end
