require "../spec_helper"

@[AlwaysInline]
private def fn(input)
  Iom::UrlAbbr.url_abbr(input)
end

describe "HTTP::Params" do
  it "handles HTTP::Params.from_hash with symbols as keys" do
    actual_value = HTTP::Params.from_hash(Hash(Symbol, String){
      :a => "b",
    }).to_s
    actual_value.should eq "a=b"
  end
  it "handles HTTP::Params.from_hash when value is Int64" do
    actual_value = HTTP::Params.from_hash(Hash(String, Int64){
      "a" => 4_i64,
    }).to_s
    actual_value.should eq "a=4"
  end
  it "handles HTTP::Params.from_hash when value is Bool" do
    actual_value = HTTP::Params.from_hash(Hash(Symbol, Bool){
      :a => true,
    }).to_s
    actual_value.should eq "a=true"
  end
  it "handles HTTP::Params.from_hash when value could be nil" do
    actual_value = HTTP::Params.from_hash(Hash(Symbol, String | Int64 | Bool | Nil){
      :a => 4_i64,
      :b => "eggs",
      :c => nil,
      :d => true,
    }).to_s
    actual_value.should eq "a=4&b=eggs&c=&d=true"
  end
end
