require "../../request/settings/updateprofile"

private alias HasUserAddEmail = (Kpbb::Request::Settings::AddEmail)

class Kpbb::Validator::User::AddEmail < Accord::Validator
  def initialize(context : HasUserAddEmail)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if (value = @context.add_email.presence).nil?
      # no change will be applied for nil
      errors.add(:add_email, "The Email address is too short.")
      return
    end
    if (at = value.rindex('@')).nil?
      # no change will be applied for nil
      errors.add(:add_email, "The Email address is invalid.")
      return
    end
    if (dot = value.rindex('.')).nil?
      # no change will be applied for nil
      errors.add(:add_email, "The Email address is invalid.")
      return
    end
    if at > dot
      # no change will be applied for nil
      errors.add(:add_email, "The Email address is invalid.")
      return
    end
    size = value.size

    if size > 320
      errors.add(:add_email, "The Email address must be under 320 characters.")
    end
  end
end
