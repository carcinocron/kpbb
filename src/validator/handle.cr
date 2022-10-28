require "accord"
require "../request/registeruser"
require "../request/loginuser"

alias HasHandle = (Kpbb::Request::RegisterUser | Kpbb::Request::LoginUser)

class Kpbb::Validator::Handle < Accord::Validator
  def initialize(context : HasHandle)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.handle.nil? || @context.handle == ""
      errors.add(:handle, "Handle required.")
      return
    end
    size = @context.handle.not_nil!.size
    errors.add(:handle, "Handle must start with a letter.") unless @context.handle =~ /^[A-Za-z]/
    errors.add(:handle, "Handle must end with a letter or number.") unless @context.handle =~ /[A-Za-z0-9]$/
    errors.add(:handle, "Handle must only have letters, numbers, dash and underscore.") unless @context.handle =~ /[A-Za-z0-9_-]*/
    errors.add(:handle, "Handle must be between 3 and 32 characters.") if size < 3 || size > 32
    errors.add(:handle, "Handle must not abuse dashes and underscores.") if @context.handle =~ /[-_]{2,}/

    if errors[:handle].empty?
      case @context
      when Kpbb::Request::RegisterUser
        if handle_taken?
          errors.add(:handle, "Handle already taken.")
        end
      when Kpbb::Request::LoginUser
        if !handle_taken?
          errors.add(:handle, "Account not found.")
        end
      end
    end
  end

  def handle_taken? : Bool
    taken = Kpbb.db.query_one(HANDLE_TAKEN_QUERY, @context.handle.not_nil!.downcase, as: {Bool})
  end
end

private HANDLE_TAKEN_QUERY = "SELECT EXISTS(
  SELECT 1 FROM users WHERE lower(users.handle) = $1
) as taken"
