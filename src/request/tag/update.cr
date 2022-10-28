require "accord"
require "../../validator/**"

struct Kpbb::Request::Tag::Update
  property model : Kpbb::Tag
  property input : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)

  def initialize(@model : Kpbb::Tag, @input : HTTP::Params)
    @query = "UPDATE tags SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new

    nqm = NextQuestionMark.new

    if input.has_key? "active"
      @model.active = input.truthy? "active"
      @sets << "active = " + nqm.next
      @bindings << @model.active
    end
    if @sets.size > 0
      # @sets << "updated_at = NOW()"
      @query += @sets.join(", ")
      @query += " WHERE id = " + nqm.next
      @bindings << @model.id
    end
  end

  include Accord

  # include MoreAccord
  # validates_with [ Kpbb::Validator::Tag::Url, Kpbb::Validator::Tag::DomainId ]

  def save
    if @sets.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
