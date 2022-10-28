# require "../../request/channel/update"
require "../../request/channel/create"

private alias HasChannelCreatedbyId = (Kpbb::Request::Channel::Create)

class Kpbb::Validator::Channel::CreatedbyId < Accord::Validator
  def initialize(context : HasChannelCreatedbyId)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.creator_id.nil? || @context.model.creator_id == ""
      errors.add(:creator_id, "Channel must have a creator.")
      return
    end
    # @todo reject users from making too many channels
    # @todo reject users with bad reputation from making channels
  end
end
