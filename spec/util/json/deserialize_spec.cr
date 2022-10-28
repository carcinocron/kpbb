require "json"
require "../../spec_helper"

# just needed to prove this was not an error in JSON
describe "JSON::deserialize" do
  it "can be caught" do
    a = Foo.from_json("{\"bar\":\"v\", \"yeet\":\"v\"}")
    a = Foo.from_json("{\"bar\":\"v\", \"yeet\":null}")
    a = Foo.from_json("{\"bar\":\"v\"}")

    begin
      a = Foo.from_json("{\"bar\":\"v\", \"yeet\":4}")
    rescue ex
    end

    begin
      a = Foo.from_json("{\"bar\":null, \"yeet\":\"v\"}")
    rescue ex
    end

    begin
      a = Foo.from_json("{\"bar\":4, \"yeet\":\"v\"}")
    rescue ex
    end

    begin
      a = Foo.from_json("{\"yeet\":\"v\"}")
    rescue ex
    end
  end
end

private struct Foo
  include JSON::Serializable
  getter bar : String
  getter yeet : String?
end
