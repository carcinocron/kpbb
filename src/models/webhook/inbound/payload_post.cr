struct Kpbb::Webhook::Inbound::PayloadPost
  Kpbb::Util::Model.select
  Kpbb::Util::Model.find_by_dual_bigints post_id, user_id
  @@table = "webhook_inbound_payloadposts"

  def self.select_columns : Array(String)
    ["payload_id", "endpoint_id", "post_id"]
  end

  property payload_id : Int64
  property endpoint_id : Int64
  property post_id : Int64

  def initialize(
    @payload_id : Int64,
    @endpoint_id : Int64,
    @post_id : Int64
  )
  end

  def initialize(rs : DB::ResultSet)
    @payload_id = rs.read(Int64)
    @endpoint_id = rs.read(Int64)
    @post_id = rs.read(Int64)
  end

  def self.fetch_page(env) : Page(self)
    nqm = NextQuestionMark.new
    query = "SELECT #{self.select} FROM #{@@table} "
    bindings = Array(::Kpbb::PGValue).new
    where = Array(String).new

    # user_id = env.session.userId?
    # pagination_before_after "webhook_inbound_payloadposts"
    # if where.size > 0
    #   query += "WHERE "+where.join(" AND ")
    # end

    page = Page(self).new env do |page|
      pagination_offset_limit
      Kpbb.db.query(query, args: bindings) do |rs|
        rs.each { page.collection << self.new(rs) }
      end
    end
  end
end
