require "../../request/settings/updateprofile"

private alias HasUserPronouns = (Kpbb::Request::Settings::UpdateProfile)

class Kpbb::Validator::User::Pronouns < Accord::Validator
  def initialize(context : HasUserPronouns)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    if @context.pronouns.nil?
      # no change will be applied for nil
      return
    end
    size = @context.pronouns.not_nil!.size
    if size > 16
      errors.add(:pronouns, "Pronouns must be under 16 characters.")
    end
  end
end
