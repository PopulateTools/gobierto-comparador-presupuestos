# Writes app/assets/javascripts/i18n/translations.js from the Rails
# translations, following config/i18n.yml.
module I18nJsExport
  def self.call
    Dir.chdir(Rails.root) do
      FileUtils.mkdir_p("app/assets/javascripts/i18n")
      I18nJS.call(config_file: "config/i18n.yml")
    end
  end
end
