alias HasCurrentPassword = (Kpbb::Request::Settings::ChangePassword)

class Kpbb::Validator::CurrentPassword < Accord::Validator
  def initialize(context : HasCurrentPassword)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.current_password.nil? || @context.current_password == ""
      errors.add(:current_password, "Current password required.")
      return
    end
    size = @context.current_password.not_nil!.size
    if size < 8
      errors.add(:current_password, "Current password must be at least 8 characters.")
      return
    end
    if @context.current_password == @context.password
      errors.add(:current_password, "Current password must be different from new password.")
      return
    end
    password = Kpbb::Password.find_by_userpw_id?(@context.user_id)

    # scenario: user does not have a password.
    # We don't want to reveal that specific detail
    # We also don't want them to succeed with a change password attempt
    if password.nil?
      errors.add(:password, BAD_CURRENT_PASSWORD)
      return
    end

    hashed_password = Crypto::Bcrypt::Password.new(password.hash)

    if !(hashed_password.verify @context.current_password)
      errors.add(:current_password, BAD_CURRENT_PASSWORD)
    end
  end
end

private BAD_CURRENT_PASSWORD = "Current password did not match."
