require "accord"
require "../../validator/**"

struct Kpbb::Request::Link::Update
  property model : Kpbb::Link
  property input : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)

  def initialize(@model : Kpbb::Link, @input : HTTP::Params)
    @query = "UPDATE links SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new

    nqm = NextQuestionMark.new

    if input.has_key? "active"
      @model.active = input["active"] == "true" || input["active"] == "1"
      @sets << "active = " + nqm.next
      @bindings << @model.active
    end
    if input.truthy? "reset_meta"
      @model.meta = nil
      @sets << "meta = NULL"
    end
    if @sets.size > 0
      @sets << "updated_at = NOW()"
      @query += @sets.join(", ")
      @query += " WHERE id = " + nqm.next
      @bindings << @model.id
    end
  end

  include Accord

  # include MoreAccord
  # validates_with [ Kpbb::Validator::Link::Url, Kpbb::Validator::Link::DomainId ]

  def save
    if @sets.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
