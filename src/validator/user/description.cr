require "../../request/settings/updateprofile"

private alias HasUserDescription = (Kpbb::Request::Settings::UpdateProfile)

class Kpbb::Validator::User::Description < Accord::Validator
  def initialize(context : HasUserDescription)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.bio.nil?
      # no change will be applied for nil
      return
    end
    size = @context.bio.not_nil!.size
    if size > 255
      errors.add(:bio, "Description must be under 256 characters.")
    end
  end
end
