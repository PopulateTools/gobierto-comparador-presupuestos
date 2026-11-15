module GobiertoBudgets
    class SearchController < GobiertoBudgets::ApplicationController
    include GobiertoBudgets::ApplicationHelper

    def index
      respond_to do |format|
        format.json do
          render json: {
            suggestions: Place.search(params[:query])
          }.to_json
        end
      end
    end

    def categories
      year = params[:year].to_i
      area = params[:area]
      kind = params[:kind]
      place = place_from_params

      this_year_codes = get_year_codes(place, area, kind, year)

      klass_name = params[:area] == 'economic' ? EconomicArea : FunctionalArea
      query = params.require(:query).downcase
      suggestions = klass_name.all_items[params[:kind]].select{|k,v| this_year_codes.include?(k) && v.downcase.include?(query) }

      respond_to do |format|
        format.json do
          render json: {
            suggestions: suggestions.map do |k,v|
              {
                value: v,
                data: {
                  url: location_budget_line_path(place.slug, year, k, kind, area)
                }
              }
            end
          }.to_json
        end
      end
    end

    private

    def place_from_params
      collection_key = params[:places_collection]&.to_sym || :ine

      collection_key == :ine ? INE::Places::Place.find_by_slug(params[:slug]) : GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.collection(collection_key).find { |place| place.slug == params[:slug] }
    end

    def get_year_codes(place, area, kind, year)
      query = {
        query: {
          bool: {
            must: [
              {term: { organization_id: place.id }},
              {term: { kind: kind}},
              {term: { year: year }},
              {term: { type: area }},
            ]
          }
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query
      response['hits']['hits'].map{|h| h['_source']['code'] }
    end
  end
end
