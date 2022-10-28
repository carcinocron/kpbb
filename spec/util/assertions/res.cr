def get_id(res : HTTP::Client::Response)
  Int64
  # it should be parsable into {"id" => Int64}
  body = IdFromJson.from_json(res.body)
  # it should only be {"id" => Int64}
  body.id.not_nil!
end

def assert_json(res)
  res.body.should start_with "{"
  res.body.should end_with "}"
end
