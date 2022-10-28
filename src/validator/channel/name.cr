require "../../request/channel/update"
require "../../request/channel/create"

private alias HasChannelDisplayName = (Kpbb::Request::Channel::Create | Kpbb::Request::Channel::Update)

class Kpbb::Validator::Channel::DisplayName < Accord::Validator
  def initialize(context : HasChannelDisplayName)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    new_value = @context.input["dname"]?.presence
    if @context.model.id
      unless @context.input.has_key?("dname")
        # no change
        return
      end
      if new_value && @context.model.dname.presence == new_value
        # no change
        return
      end
    end

    # unless new_value
    #   errors.add(:dname, "Name required.")
    #   return
    # end
    size = new_value.try(&.size) || 0
    if size > 48
      errors.add(:dname, "Display Name must be under 48 characters.")
    end
  end
end
