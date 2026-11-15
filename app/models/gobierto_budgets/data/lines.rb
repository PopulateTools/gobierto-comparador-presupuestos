module GobiertoBudgets
  module Data
    class Lines
      def initialize(options = {})
        @what = options[:what]
        @variable = @what == 'total_budget' ? 'amount' : 'amount_per_inhabitant'
        @year = options[:year]
        @organization = options[:organization]
        @is_comparison = @organization.is_a?(Array)
        @kind = options[:kind]
        @code = options[:code]
        @area = options[:area]
        if @code
          @variable = @what == 'total_budget' ? 'amount' : 'amount_per_inhabitant'
          areas = @area == 'economic' ? EconomicArea : FunctionalArea
          @category_name = areas.all_items[@kind][@code]
        end
      end

      def generate_json
        json = {
          kind: @kind,
          year: @year,
          title: lines_title,
          budgets: {
            @what => budget_values
          }
        }

        return json.to_json
      end

      private

      def mean_places_collection(places_collection_key)
        filters = [{ terms: { organization_id: GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.collection_organization_ids(places_collection_key) } }]

        mean_results(filters)
      end

      def mean_province(only_municipalities: false)
        filters = [ {term: { province_id: @organization.province_id }} ]
        filters << { exists: { field: "ine_code" } } if only_municipalities

        mean_results(filters)
      end

      def mean_autonomy(only_municipalities: false)
        filters = [ {term: { autonomy_id: @organization.autonomous_region_id }} ]
        filters << { exists: { field: "ine_code" } } if only_municipalities

        mean_results(filters)
      end

      def mean_national(only_municipalities: false)
        filters = []
        filters << { exists: { field: "ine_code" } } if only_municipalities

        mean_results(filters)
      end

      def mean_results(filters)
        if @code
          filters.push({term: { code: @code }})
          filters.push({term: { kind: @kind }})
        end
        filters.push({term: { type: type }})

        query = {
          query: {
            bool: {
              must: filters
            }
          },
          size: 0,
          "aggs": {
            "#{@variable}_per_year": {
              "terms": {
                "field": "year",
                size: 10_000
              },
              "aggs": {
                "budget_sum": {
                  "sum": {
                    "field": "#{@variable}"
                  }
                }
              }
            }
          }
        }

        response = SearchEngine.client.search index: index, body: query
        data = {}
        response['aggregations']["#{@variable}_per_year"]['buckets'].each do |r|
          data[r['key']] = (r['budget_sum']['value'].to_f / r['doc_count'].to_f).round(2)
        end

        result = []
        data.sort_by{|k,_| k }.each do |year, v|
          if year <= GobiertoBudgets::SearchEngineConfiguration::Year.last
            result.push({
              date: year.to_s,
              value: v,
              dif: data[year-1] ? delta_percentage(v, data[year-1]) : 0
            })
          end
        end

        result.reverse
      end

      def organizations_values(organization = nil)
        organization = @organization unless organization.present?
        filters = [{ term: { organization_id: organization.id } }]

        if @code
          filters.push(term: { code: @code })
          filters.push(term: { kind: @kind })
        end

        filters.push({ term: { type: type }})

        query = {
          sort: [
            { year: { order: 'desc' } }
          ],
          query: {
            bool: {
              must: filters
            }
          },
          size: 10_000
        }

        result = []
        response = SearchEngine.client.search index: index, body: query
        values = Hash[response['hits']['hits'].map{|h| h['_source']}.map{|h| [h['year'],h[@variable]] }]
        values.each do |k,v|
          dif = 0
          if old_value = values[k -1]
            dif = delta_percentage(v, old_value)
          end
          if k <= GobiertoBudgets::SearchEngineConfiguration::Year.last
            result.push({date: k.to_s, value: v, dif: dif})
          end
        end
        result
      end

      def budget_values
        return comparison_values if @is_comparison

        values = [{ name: @organization.name, values: organizations_values }]

        if @organization.city_council?
          if (places_collection = @organization.place.custom_place_id).present?
            values << { name: "mean_#{places_collection}", values: mean_places_collection(places_collection) }
          else
            values += [
              { name: "mean_province", values: mean_province(only_municipalities: false) },
              { name: "mean_autonomy", values: mean_autonomy(only_municipalities: false) }
            ]
            values << { name: "mean_national", values: mean_national(only_municipalities: false) } unless GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          end
        end

        values
      end

      def comparison_values
        @organization.map do |organization|
          {
            "name": organization.name,
            "values": organizations_values(organization)
          }
        end
      end

      def lines_title
        if @code.nil?
          @what == 'total_budget' ? I18n.t('gobierto_budgets.api.data.total_expense') : I18n.t('gobierto_budgets.api.data.expense_per_inhabitant')
        else
          @what == 'total_budget' ? @category_name : I18n.t('gobierto_budgets.api.data.category_per_inhabitant', category: @category_name)
        end
      end

      def delta_percentage(current_year_value, old_value)
        (((current_year_value.to_f - old_value.to_f)/old_value.to_f) * 100).round(2)
      end

      def index
        SearchEngineConfiguration::TotalBudget.index_forecast
      end

      def type
        if @code.nil?
          SearchEngineConfiguration::TotalBudget.type
        else
          @area
        end
      end
    end
  end
end
