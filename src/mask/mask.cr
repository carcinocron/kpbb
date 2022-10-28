module Kpbb::Mask
  enum Mask : Int16
    None             =   0_16
    Channel          =   1_16
    ChannelModerator =   2_16
    Anon             = 100_16

    def hide_createdby? : Bool
      return false if self == Mask::None
      return true
    end

    def to_db_value : Int16?
      return nil if self == Mask::None
      value
    end

    def self.parse_from_input(input : Nil) : Kpbb::Mask::Mask?
      nil
    end

    def self.parse_from_input(input : String) : Kpbb::Mask::Mask?
      input = input.strip
      if input_i16 = input.to_i16?
        Kpbb::Mask::Mask.new(input_i16)
      elsif input
        Kpbb::Mask::Mask.parse(input)
      else
        nil
      end
    end

    def self.parse_from_db(input_i16 : Int16?) : Kpbb::Mask::Mask
      if input_i16
        Kpbb::Mask::Mask.new(input_i16)
      else
        Kpbb::Mask::Mask::None
      end
    end

    def dname : String
      self.to_s.underscore.gsub("_", " ").titleize
    end
  end
end
