# @link https://crystal-lang.org/reference/syntax_and_semantics/annotations.html

# class Kpbb::Orm::Query
#   def initialize(@io = IO::Memory.new, @bindings = Array(Kpbb::PGValue).new)
#     @db = Kpbb.db
#   end
# end

BINDING_PREFIX = "$"
BINDING_LIST_SEPERATOR = ", "

class Kpbb::Orm::Query
  def initialize(
    @io = IO::Memory.new,
    @bindings : Array(Kpbb::PGValue)? = nil,
    @cbp = 0u16)
    # @db = Kpbb.db
    @had_first_where = false
  end

  def bindings : Array(Kpbb::PGValue)
    @bindings ||= Array(Kpbb::PGValue).new
  end

  def has_bindings? : Bool
    ((b = @bindings) && b.size > 0)
  end

  def query : IO::Memory
    @io
  end

  def where (clause) : Nil
    if (@had_first_where)
      @io << " AND "
      @io << clause
    else
      @had_first_where = true
      @io << " WHERE "
      @io << clause
    end
  end

  # last binding placeholder
  def lbp : UInt16
    @cbp
  end

  # next binding placeholder
  def nbp : UInt16
    (@cbp += 1)
  end

  def << (value) : Nil
    @io << value
  end

  def bind (value) : IO
    self.bindings << value
    io = IO::Memory.new
    io << BINDING_PREFIX
    io << self.nbp
    io
  end

  def bind (*values) : IO::Memory
    bindings = self.bindings
    io = IO::Memory.new
    values.each_with_index do |v, index|
      io << BINDING_LIST_SEPERATOR if index > 0
      io << BINDING_PREFIX
      io << self.nbp
      bindings << v
    end
    io
  end

  # keep in sync with the older macro versions of these
  def pagination_before_after (req : HTTP::Server::Context, table : String)
    if (v = req.params.query["after"]?)
      where "#{table}.id > #{bind(v)}"
    end
    if (v = req.params.query["before"]?)
      where "#{table}.id < #{bind(v)}"
    end
  end
  def pagination_offset_limit (page)
    self << " OFFSET #{bind(page.offset)} LIMIT #{bind(page.perpage + 1)}"
  end

  # def to_debug
  #   ({ :query => self.query.to_s, :bindings => self.bindings })
  # end
end