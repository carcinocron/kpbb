require "../../request/settings/updatetheme"

private alias HasThemeId = (Kpbb::Request::Settings::UpdateTheme)

class Kpbb::Validator::Settings::ThemeId < Accord::Validator
  def initialize(context : HasThemeId)
    @context = context
  end

  def call(errors : Accord::ErrorList)
    theme_id = @context.theme_id
    if theme_id.nil?
      # ignore
      return
    end

    theme = Kpbb::Themes.map_by_id[theme_id]?
    if !theme
      errors.add(:theme_id, "Invalid theme.")
      return
    end
  end
end
