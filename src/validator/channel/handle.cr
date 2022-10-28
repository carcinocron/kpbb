require "accord"
require "../../request/channel/create"
require "../../request/channel/update"

private alias HasChannelHandle = (Kpbb::Request::Channel::Create | Kpbb::Request::Channel::Update)

class Kpbb::Validator::Channel::Handle < Accord::Validator
  def initialize(context : HasChannelHandle)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    new_value = @context.input["handle"]?.presence
    if @context.model.id
      unless @context.input.has_key?("handle")
        # no change
        return
      end
      if new_value && @context.model.handle.presence == new_value
        # no change
        return
      end
    end

    unless new_value
      errors.add(:handle, "Handle required.")
      return
    end
    size = new_value.not_nil!.size
    errors.add(:handle, "Handle must start with a letter.") unless @context.model.handle =~ /^[A-Za-z]/
    errors.add(:handle, "Handle must end with a letter or number.") unless @context.model.handle =~ /[A-Za-z0-9]$/
    errors.add(:handle, "Handle must only have letters, numbers, dash and underscore.") unless @context.model.handle =~ /[A-Za-z0-9_-]*/
    errors.add(:handle, "Handle must be between 3 and 32 characters.") if size < 3 || size > 32
    errors.add(:handle, "Handle must not abuse dashes and underscores.") if @context.model.handle =~ /[-_]{2,}/

    if errors[:handle].empty?
      if handle_taken? new_value
        errors.add(:handle, "Handle already taken.")
      end
    end
  end

  def handle_taken?(new_value : String) : Bool
    bindings = Array(::Kpbb::PGValue).new
    bindings << new_value.downcase

    if model_id = @context.model.id
      bindings << model_id
      bindings << model_id
      query = <<-SQL
      SELECT EXISTS(
        SELECT 1 FROM channels WHERE lower(channels.handle) = $1
        AND channels.id > $2
        UNION
        SELECT 1 FROM channels WHERE lower(channels.handle) = $1
        AND channels.id < $3
      ) as taken
      SQL
    else
      query = <<-SQL
      SELECT EXISTS(
        SELECT 1 FROM channels WHERE lower(channels.handle) = $1
      ) as taken
      SQL
    end
    taken = Kpbb.db.query_one(query, args: bindings, as: {Bool})
  end
end
