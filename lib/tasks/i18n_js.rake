namespace :i18n do
  namespace :js do
    desc "Export the translations used by the JavaScript I18n object"
    task export: :environment do
      I18nJsExport.call
    end
  end
end

Rake::Task["assets:precompile"].enhance(["i18n:js:export"])
