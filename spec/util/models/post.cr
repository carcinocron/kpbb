private INSERT = <<-SQL
  INSERT INTO posts (
    channel_id, parent_id, creator_id,
    title, tags, url, link_id,
    body_md, body_html, cc_i16, ip,
    score, dreplies, treplies, mask, posted, draft,
    published_at, ptype, created_at, updated_at)
  VALUES (
    $1, $2, $3,
    $4, $5, $6, $7,
    $8, $9, $10, ($11)::INET,
    $12, $13, $14, $15, $16, $17,
    $18, $19, NOW(), NOW())
  returning id, created_at, updated_at
SQL

struct Kpbb::Post
  def self.factory(
    channel_id : Int64,
    creator_id : Int64,
    title : String? = "post title",
    tags : String? = nil,
    url : String? = nil,
    link_id : Int64? = nil,
    body_md : String? = nil,
    body_html : String? = nil,
    cc_i16 : Int16 = Iom::CountryCode::UnitedStates,
    ip : String? = "127.0.0.1",
    posted : Bool = true,
    draft : Bool = true,
    score : Int32 = 0,
    dreplies : Int16 = 0_i16,
    treplies : Int16 = 0_i16,
    mask : Kpbb::Mask::Mask = Kpbb::Mask::Mask::None,
    published_at : Time? = nil,
    parent_id : Int64? = nil,
    ptype : Kpbb::Post::Type = Kpbb::Post::Type::None
  ) : self
    id, created_at, updated_at = Kpbb.db.query_one(INSERT, args: [
      channel_id,
      parent_id,
      creator_id,
      title,
      tags,
      url,
      link_id,
      body_md,
      body_html,
      cc_i16,
      ip,
      score,
      dreplies,
      treplies,
      mask.to_db_value,
      posted,
      draft,
      published_at,
      ptype.to_db_value,
    ], as: {Int64, Time, Time})

    if body_html.nil? && !body_md.nil?
      body_html = Markdown.to_html(body_md.not_nil!)
    end

    self.new(
      id: id,
      channel_id: channel_id,
      parent_id: parent_id,
      creator_id: creator_id,
      title: title,
      tags: tags,
      url: url,
      link_id: link_id,
      body_md: body_md,
      body_html: body_html,
      cc_i16: cc_i16,
      ip: ip,
      posted: posted,
      draft: draft,
      score: score,
      dreplies: dreplies,
      treplies: treplies,
      mask: mask,
      published_at: published_at,
      ptype: ptype,
      created_at: created_at,
      updated_at: updated_at)
  end
end
