module Iom::CountryCode
  Unknown      = Iom::CountryCode.to_i16("xx")
  Tor          = Iom::CountryCode.to_i16("t1")
  UnitedStates = Iom::CountryCode.to_i16("us")

  module HasCountryCodeNaturalKey
    @[AlwaysInline]
    def cc : String?
      Iom::CountryCode.from_i16(self.cc_i16).presence
    end

    def cc_i16 : String?
      Iom::CountryCode.from_i16(@cc_i16).presence
    end

    def cc_i16=(cc_i16 : String)
      @cc_i16 = Iom::CountryCode.to_i16(cc_i16)
    end

    def cc_i16=(@cc_i16 : Int16)
    end

    def cc_i16=(cc_i16 : Nil)
      @cc_i16 = 0_i16
    end
  end

  def self.to_i16(input : Nil) : Int16
    return 0_i16
  end

  def self.to_i16(input : String) : Int16
    input = input.strip.downcase
    return 0_i16 if input.size != 2
    a = input.codepoint_at(0).to_i16
    b = input.codepoint_at(1).to_i16
    # the only exception for allowing a number is cloudflare's Tor Network indicator
    if !(b == 49_i16 && a == 116_i16)
      return 0_i16 unless 123_i16 > a > 96_i16
      return 0_i16 unless 123_i16 > b > 96_i16
    end
    return (a * 256_i16) + b
  end

  def self.from_i16(input : Nil) : String?
    return nil
  end

  def self.from_i16(input : Int16?) : String?
    b = input % 256_i16
    a = (input - b) // 256

    # nil if not both are a-z
    return nil unless 123_i16 > a > 96_i16

    # the only exception for allowing a number is cloudflare's Tor Network indicator
    return "t1" if (b == 49_i16 && a == 116_i16)

    # nil if not both are a-z
    return nil unless 123_i16 > b > 96_i16

    slice = Slice(UInt8).new(2)
    slice[0] = a.to_u8
    slice[1] = b.to_u8
    String.new(slice)
  end
end
