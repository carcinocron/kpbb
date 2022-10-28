require "accord"
require "../../validator/**"

struct Kpbb::Request::Domain::Update
  property model : Kpbb::Domain
  property input : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)

  def initialize(@model : Kpbb::Domain, @input : HTTP::Params)
    @query = "UPDATE domains SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new

    nqm = NextQuestionMark.new

    if input.has_key? "active"
      @model.active = input.truthy? "active"
      @sets << "active = " + nqm.next
      @bindings << @model.active
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
  # validates_with [ Kpbb::Validator::Domain::Url, Kpbb::Validator::Domain::DomainId ]

  def save
    if @sets.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
