require "../../request/settings/updateprofile"

private alias HasUserDisplayName = (Kpbb::Request::Settings::UpdateProfile)

class Kpbb::Validator::User::DisplayName < Accord::Validator
  def initialize(context : HasUserDisplayName)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.dname.nil?
      # no change will be applied for nil
      return
    end
    size = @context.dname.not_nil!.size

    if size > 48
      errors.add(:dname, "Display Name must be under 48 characters.")
    end
  end
end
