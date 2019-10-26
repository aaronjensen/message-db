CREATE OR REPLACE FUNCTION get_category_messages(
  category_name varchar,
  "position" bigint DEFAULT 0,
  batch_size bigint DEFAULT 1000,
  condition varchar DEFAULT NULL
)
RETURNS SETOF message
AS $$
DECLARE
  _command text;
BEGIN
  position := COALESCE(position, 0);
  batch_size := COALESCE(batch_size, 1000);

  _command := '
    SELECT
      id::varchar,
      stream_name::varchar,
      type::varchar,
      position::bigint,
      global_position::bigint,
      data::varchar,
      metadata::varchar,
      time::timestamp
    FROM
      messages
    WHERE
      category(stream_name) = $1 AND
      global_position >= $2';

  if get_category_messages.condition is not null then
    _command := _command || ' AND
      %s';
    _command := format(_command, get_category_messages.condition);
  end if;

  _command := _command || '
    ORDER BY
      global_position ASC
    LIMIT
      $3';

  RAISE NOTICE '%', _command;
  RAISE NOTICE 'Category Name ($1): %', get_category_messages.category_name;
  RAISE NOTICE 'Position ($2): %', get_category_messages.position;
  RAISE NOTICE 'Batch Size ($3): %', get_category_messages.batch_size;
  RAISE NOTICE 'Condition ($4): %', get_category_messages.condition;

  RETURN QUERY EXECUTE _command USING
    get_category_messages.category_name,
    get_category_messages.position,
    get_category_messages.batch_size;
END;
$$ LANGUAGE plpgsql
VOLATILE;
