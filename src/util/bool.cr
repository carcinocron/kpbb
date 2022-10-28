struct Bool
  def to_i16 : Int16
    self ? 1_i16 : 0_i16
  end
end

def one_or_zero(value : Bool|String|Int16|Nil) : Int16
  return 1_i16 if value === "true"
  return 1_i16 if value === "1"
  return 1_i16 if value === 1_i16
  return 1_i16 if value === true
  0_i16
end

def one_or_zero_s(value : Bool|String|Int16|Nil) : String
  return "1" if value === "true"
  return "1" if value === "1"
  return "1" if value === 1_i16
  return "1" if value === true
  "0"
end