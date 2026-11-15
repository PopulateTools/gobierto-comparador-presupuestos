module GobiertoBudgets
  class PagesController < GobiertoBudgets::ApplicationController

    DEFAULT_SEARCH_EXAMPLES = {
      ine: [
        ["Santander", "santander"],
        ["Talaván", "talavan"],
        ["Órgiva", "orgiva"],
        ["Zaragoza", "zaragoza"]
      ],
      deputation_eu: [
        ["Diputación Foral de Vizcaya", "dip-bizkaia"],
        ["Diputación Foral de Álava", "dip-alava"],
        ["Diputación Foral de Guipúzcoa", "dip-gipuzkoa"]
      ]
    }.freeze

    DEFAULT_COMPARE_EXAMPLES = {
      ine: [
        ["Coruña + Pontevedra + Lugo + Ferrol", "coruna-a:pontevedra:lugo:ferrol"],
        ["Madrid + Barcelona + Valencia + Sevilla", "madrid:barcelona:valencia:sevilla"]
      ],
      deputation_eu: [
        ["Vizcaya + Álava + Guipúzcoa", "dip-bizkaia:dip-alava:dip-gipuzkoa"]
      ]
    }.freeze

    caches_action :home, :ranking, :deputations_ranking, cache_path: ->(c) { { locale: I18n.locale, places_collection: c.send(:places_collection_key) } }
    helper_method :search_examples, :compare_examples, :ranking_year

    def home
    end

    def about
    end

    def pro
    end

    def faq
    end

    def legal_cookies
    end

    def legal_legal
    end

    def legal_privacy
    end

    def request_access
      render layout: false
    end

    def ranking
      @places_collection = params[:places_collection]&.to_sym || :ine
      @ranking_paths = ranking_paths(
        ["I", "economic", "amount", 344],
        ["G", "functional", "amount_per_inhabitant", 336],
        ["G", "functional", "amount", 342],
        ["G", "functional", "amount_per_inhabitant", 165],
        ["G", "functional", "amount", 162],
        ["G", "functional", "amount_per_inhabitant", 44],
        ["I", "economic", "amount", 313],
        ["G", "functional", "amount_per_inhabitant", 171]
      )
    end

    def deputations_ranking
      @places_collection = params[:places_collection]&.to_sym || :ine
      @ranking_paths = ranking_paths(
        ["I", "economic", "amount", 391],
        ["G", "functional", "amount_per_inhabitant", 336],
        ["G", "functional", "amount", 341],
        ["G", "functional", "amount_per_inhabitant", 136],
        ["G", "functional", "amount", 231],
        ["G", "functional", "amount_per_inhabitant", 44],
        ["I", "economic", "amount", "220-07"],
        ["G", "functional", "amount_per_inhabitant", 414]
      )

      render :ranking
    end

    def map
      @year = params[:year].to_i
      unless GobiertoBudgets::SearchEngineConfiguration::Year.all.include?(@year)
        redirect_to gobierto_budgets_map_path(year: GobiertoBudgets::SearchEngineConfiguration::Year.last) and return false
      end
    end

    private

    def ranking_paths(*args_list)
      args_list.map do |args|
        gobierto_budgets_api_data_ranking_path(
          ranking_year,
          *args,
          format: :json,
          only_municipalities: true,
          places_collection: @places_collection
        )
      end
    end

    def ranking_year
      @ranking_year ||= GobiertoBudgets::BudgetTotal.last_year(places_collection_key)
    end

    def search_examples
      @search_examples ||= begin
                             return DEFAULT_SEARCH_EXAMPLES if Settings.search_examples.blank?

                             GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.places_keys.each_with_object({}) do |key, examples|
                               examples[key] = expand_location_values(Settings.search_examples[key], key) || DEFAULT_SEARCH_EXAMPLES[key]
                             end
                           end
    end

    def compare_examples
      @compare_examples ||= begin
                              return DEFAULT_COMPARE_EXAMPLES if Settings.compare_examples.blank?

                              GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.places_keys.each_with_object({}) do |key, examples|
                                examples[key] = if Settings.compare_examples[key].present?
                                                  Settings.compare_examples[key].map do |list|
                                                    locations = expand_location_values(list, key)
                                                    next if locations.blank?

                                                    [locations.map(&:first).join(" + "), locations.map(&:last).join(":")]
                                                  end.compact
                                                else
                                                  DEFAULT_COMPARE_EXAMPLES[key]
                                                end
                              end
                            end
    end

    def expand_location_values(slugs, places_collection)
      return unless slugs.present?

      slugs.map do |slug|
        location = GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find_by_slug(slug, places_collection:)
        next if location.blank?

        [location.name, location.slug]
      end.compact
    end
  end
end
