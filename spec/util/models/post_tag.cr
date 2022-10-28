struct TestPostTag
  property tag_id : Int64
  property post_id : Int64
  property value : String

  def initialize(rs : DB::ResultSet)
    @post_id = rs.read(Int64)
    @tag_id = rs.read(Int64)
    @value = rs.read(String)
  end

  def self.all : Array(self)
    list = Array(self).new
    query = <<-SQL
      SELECT post_id, tag_id, value
      FROM tags JOIN post_tag ON tags.id = post_tag.tag_id
    SQL
    Kpbb.db.query(query) do |rs|
      rs.each { list << self.new(rs) }
    end
    list
  end
end
