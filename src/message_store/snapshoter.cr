class MessageStore::PostgresSnapshot
  include PostgresStore
  include Config

  def update(stream : String, entity : Entity)
    query = <<-SQL
      UPDATE
        #{config.entity_snapshots_table}
      SET
        position = $1,
        data = $2,
        metadata = $3,
        time = now()
      WHERE
        stream = $4
    SQL

    with_db { |db| db.exec query, entity.version, entity.to_json, entity.metadata.to_json, stream }
  end

  def init(stream : String, entity_class : Entity.class)
    query = <<-SQL
      INSERT INTO
        #{config.entity_snapshots_table}(stream, position, type, data, metadata)
      VALUES
        ($1, $2, $3, $4, $5)
    SQL

    with_db { |db| db.exec query, stream, 0, entity_class.name, nil, nil }
  end

  def fetch(stream : String) : Tuple(String?, String?)
    query = <<-SQL
      SELECT
        data,
        metadata
      FROM
        #{config.entity_snapshots_table}
      WHERE
        stream = $1
    SQL

    data, metadata = nil, nil

    with_db do |db|
      db.query(query, stream) do |rs|
        rs.each { data, metadata = rs.read(JSON::Any?, JSON::Any?) }
      end
    end

    if data.nil?
      {nil, nil}
    else
      {data.to_json, metadata.to_json}
    end
  end
end

module MessageStore::Snapshoter
  def snapshot
    @snapshot ||= PostgresSnapshot.new
  end
end
