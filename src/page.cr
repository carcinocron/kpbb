struct Page(T)
  property page : Int64
  property perpage : Int16
  property offset : Int64
  property collection : Array(T)
  property has_more : Bool
  property path_with_query : String
  property morequery : Hash(String, String | Int64 | Nil)

  def to_json : String
    collection = yield @collection
    {
      "data"            => collection,
      "perpage"         => @perpage,
      "offset"          => @offset,
      "has_more"        => @has_more,
      "morequery"       => @morequery,
      "path_with_query" => @path_with_query,
    }.to_json
  end

  def initialize(@collection, @page, @perpage : Int16 = 15_i16, @path_with_query = "/", @morequery = Hash(String, String | Int64 | Nil).new)
    @offset = (@page - 1) * @perpage
    @has_more = @collection.size == @perpage + 1
    @collection.pop if @has_more
  end

  def initialize(env, @collection = Array(T).new, @morequery = Hash(String, String | Int64 | Nil).new)
    @perpage = env.perpage
    @path_with_query = env.request.path_with_query
    @page = Page.page_from_param_string(env.params.query["page"]?).not_nil!
    @offset = (@page - 1) * @perpage
    @has_more = false
    yield self
    @has_more = @collection.size == @perpage + 1
    @collection.pop if @has_more
  end

  def show_bottom_controls : Bool
    @collection.size > 5
  end

  def number : Int64
    @page
  end

  def previous_uri : URI?
    return nil unless @page > 1
    uri = URI.parse(@path_with_query)
    query = HTTP::Params.parse(uri.query || "")
    apply_morequery
    query["page"] = (page - 1).to_s
    uri.query = query.to_s
    return uri
  end

  def current_uri : URI
    uri = URI.parse(@path_with_query)
    query = HTTP::Params.parse(uri.query || "")
    apply_morequery
    query["page"] = page.to_s
    uri.query = query.to_s
    return uri
  end

  def next_uri : URI?
    return nil unless @has_more
    uri = URI.parse(@path_with_query)
    query = HTTP::Params.parse(uri.query || "")
    apply_morequery
    query["page"] = (page + 1).to_s
    uri.query = query.to_s
    return uri
  end

  def self.page_from_param_string(input : String?) : Int64
    return 1_i64 if input.nil? || input == ""
    value : Int64 = input.to_i64? || 1_i64
    return 1_i64 if value.nil?
    return 1_i64 if 1_i64 > value
    value
  end

  def render_controls
    page = self
    render "src/views/pagination_controls.ecr"
  end
end

private macro apply_morequery
  morequery.each do |name, value|
    query[name] = value.to_s unless value.nil?
    query.delete_all name if value.nil?
  end
end
