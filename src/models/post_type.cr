enum Kpbb::Post::Type : Int16
  None    = 0
  Comment = 1
  Share   = 2
  # @action = Kpbb::ChannelAction.new(rs.read(Int16))
  Question = 100
  Answer   = 101

  def to_db_value : Int16?
    return nil if self == Kpbb::Post::Type::None
    value
  end

  def self.parse_from_input(input : Nil) : Kpbb::Post::Type?
    nil
  end

  def self.parse_from_input(input : String) : Kpbb::Post::Type?
    if input_i16 = input.to_i16?
      Kpbb::Post::Type.new(input_i16)
    elsif input
      Kpbb::Post::Type.parse(input)
    else
      nil
    end
  end

  def self.parse_from_db(input_i16 : Int16?) : Kpbb::Post::Type
    if input_i16
      Kpbb::Post::Type.new(input_i16)
    else
      Kpbb::Post::Type::None
    end
  end

  def self.parse_from_db(input_i16 : Int16?) : Kpbb::Post::Type
    if input_i16
      Kpbb::Post::Type.new(input_i16)
    else
      Kpbb::Post::Type::None
    end
  end

  def has_title? : Bool
    return true if self == Kpbb::Post::Type::None
    return true if self == Kpbb::Post::Type::Question
    return true if self == Kpbb::Post::Type::Answer
    return false
  end

  def has_url? : Bool
    return true if self == Kpbb::Post::Type::None
    return true if self == Kpbb::Post::Type::Share
    return false
  end

  def has_tags? : Bool
    return true if self == Kpbb::Post::Type::None
    return true if self == Kpbb::Post::Type::Question
    return true if self == Kpbb::Post::Type::Answer
    return false
  end

  def dname : String
    case self
    when Comment
      return "comment"
    else
      return "post"
    end
  end
end
