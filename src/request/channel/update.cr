require "accord"
require "../../validator/**"

struct Kpbb::Request::Channel::Update
  property model : Kpbb::Channel
  property input : HTTP::Params
  property query : String
  property sets : Array(String)
  property bindings : Array(::Kpbb::PGValue)

  def initialize(@model : Kpbb::Channel, @input : HTTP::Params)
    @query = "UPDATE channels SET "
    @bindings = Array(::Kpbb::PGValue).new
    @sets = Array(String).new
    # @model.dname = input["dname"] if input.has_key? "dname"
    # @model.handle = input["handle"] if input.has_key? "handle"
    # @model.bio = input["bio"] if input.has_key?("bio")

    nqm = NextQuestionMark.new

    if input.has_key? "dname"
      # @model.dname = input["dname"]
      @sets << "dname = " + nqm.next
      @bindings << input["dname"]
    end
    if input.has_key? "handle"
      # @model.handle = input["handle"]
      @sets << "handle = " + nqm.next
      @bindings << input["handle"]
    end
    if input.has_key?("bio")
      # @model.bio = input["bio"]
      @sets << "bio = " + nqm.next
      @bindings << input["bio"]
    end
    if input.has_key? "public"
      # @model.public = input.truthy?("public")
      @sets << "public = " + nqm.next
      @bindings << input.truthy?("public")
    end
    if input.has_key? "listed"
      # @model.listed = input.truthy?("public")
      @sets << "listed = " + nqm.next
      @bindings << input.truthy?("public")
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
  validates_with [
    Kpbb::Validator::Channel::Handle,
    Kpbb::Validator::Channel::DisplayName,
    Kpbb::Validator::Channel::Description,
  ]

  def save
    if @sets.size > 0
      Kpbb.db.exec @query, args: @bindings
    end
  end
end
