require "../spec_helper"

private struct HasBase62TitleUrl
  def initialize(@id : Int64, @title : String)
  end

  Kpbb::Util::Model.base62_title_url("/sprockets")
end

private struct HasBase62TitleUrlNotNil
  def initialize(@id : Int64, @title : String)
  end

  Kpbb::Util::Model.base62_title_url_not_nil("/sprockets")
end

private struct HasHandleUrl
  def initialize(@id : Int64, @handle : String)
  end

  Kpbb::Util::Model.handle_url("/sprockets")
end

private struct HasHandleUrlNotNil
  def initialize(@id : Int64, @handle : String)
  end

  Kpbb::Util::Model.handle_url_not_nil("/sprockets")
end

private struct HasBase62Url
  def initialize(@id : Int64)
  end

  Kpbb::Util::Model.base62_url("/sprockets")
end

private struct HasBase62UrlNotNil
  def initialize(@id : Int64)
  end

  Kpbb::Util::Model.base62_url_not_nil("/sprockets")
end

describe "Util::Model::Url" do
  it "makes expected outputs" do
    HasBase62TitleUrl.new(id: 1000, title: "example")
      .relative_title_url.should eq "/sprockets/example-g8"

    HasBase62TitleUrlNotNil.new(id: 1000, title: "example")
      .relative_title_url.should eq "/sprockets/example-g8"

    HasHandleUrl.new(id: 1000, handle: "example")
      .relative_url.should eq "/sprockets/example"

    HasHandleUrlNotNil.new(id: 1000, handle: "example")
      .relative_url.should eq "/sprockets/example"

    HasBase62Url.new(id: 1000)
      .relative_url.should eq "/sprockets/g8"

    HasBase62UrlNotNil.new(id: 1000)
      .relative_url.should eq "/sprockets/g8"
  end
end
