require "../../request/channel/update"
require "../../request/channel/create"

private alias HasChannelDescription = (Kpbb::Request::Channel::Create | Kpbb::Request::Channel::Update)

class Kpbb::Validator::Channel::Description < Accord::Validator
  def initialize(context : HasChannelDescription)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.model.bio.nil? || @context.model.bio == ""
      # errors.add(:bio, "Description required.")
      return
    end
    size = @context.model.bio.not_nil!.size
    if size > 255
      errors.add(:bio, "Description must be under 256 characters.")
    end
  end
end
