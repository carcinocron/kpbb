# require "../../request/post/update"
require "../../request/post/create"

private alias HasPostCreatedbyId = (Kpbb::Request::Post::Create)

class Kpbb::Validator::Post::CreatedbyId < Accord::Validator
  def initialize(context : HasPostCreatedbyId)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.creator_id.nil? || @context.model.creator_id == ""
      errors.add(:creator_id, "Post must have a creator.")
      return
    end
    # @todo reject users from making too many posts
    # @todo reject users with bad reputation from making posts
  end
end
