module GobiertoBudgets
  class BudgetLine < OpenStruct

    include CommonQueryBehavior

    INCOME = 'I'
    EXPENSE = 'G'
    ECONOMIC = 'economic'
    FUNCTIONAL = 'functional'
    AREA_NAMES = [ECONOMIC, FUNCTIONAL].freeze

    @sort_attribute ||= 'code'
    @sort_order ||= 'asc'

    # Last year with expense budget lines of the places collection, up to the last year of the comparator.
    # Some places have the total budget of a year before its budget lines are loaded, so the total is not enough.
    def self.last_year(places_collection)
      Rails.cache.fetch(["budget_line_last_year", places_collection], expires_in: 1.day) do
        organization_ids = PlaceSet.new(places_collection:).organization_ids
        query = {
          size: 0,
          query: {
            bool: {
              must: [
                { terms: { organization_id: organization_ids } },
                { term: { kind: EXPENSE } },
                { term: { type: ECONOMIC } },
                { range: { year: { lte: SearchEngineConfiguration::Year.last } } }
              ]
            }
          },
          aggs: { last_year: { max: { field: "year" } } }
        }

        response = SearchEngine.client.search(index: SearchEngineConfiguration::BudgetLine.index_forecast, body: query)
        response["aggregations"]["last_year"]["value"]&.to_i || SearchEngineConfiguration::Year.last
      end
    end

    def self.where(conditions)
      @conditions = conditions
      self
    end

    def self.search(options)

      terms = [
        { term: { kind: options[:kind] } },
        { term: { year: options[:year] } },
        { term: { type: options[:type] || 'economic' }}
      ]

      must_not_terms = []
      must_not_terms.push({exists: { field: 'functional_code'}})
      must_not_terms.push({exists: { field: 'custom_code'}})

      terms << {term: { organization_id: options[:organization_id] }} if options[:organization_id].present?
      terms << {term: { ine_code: options[:ine_code] }} if options[:ine_code].present?
      terms << {term: { parent_code: options[:parent_code] }} if options[:parent_code].present?
      terms << {term: { level: options[:level] }} if options[:level].present?
      terms << {term: { code: options[:code] }} if options[:code].present?

      if options[:range_hash].present?
        options[:range_hash].each_key do |range_key|
          terms << {range: { range_key => options[:range_hash][range_key] }}
        end
      end

      query = {
        sort: [
          { code: { order: 'asc' } }
        ],
        query: {
          bool: {
            must: terms
          }.merge(must_not_terms.present? ? { must_not: must_not_terms } : {})
        },
        aggs: {
          total_budget: { sum: { field: 'amount' } },
          total_budget_per_inhabitant: { sum: { field: 'amount_per_inhabitant' } },
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search(
        index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
        body: query
      )

      # HACK: aggregation values returned by ES are wrong. This option recalculates them.
      if options[:recalculate_aggregations] == true
        total_budget = response["hits"]["hits"].map { |h| h["_source"]["amount"] }.sum
        total_budget_per_inhabitant = response["hits"]["hits"].map { |h| h["_source"]["amount_per_inhabitant"] }.compact.sum
        response["aggregations"]["total_budget"]["value"] = total_budget
        response["aggregations"]["total_budget_per_inhabitant"]["value"] = total_budget_per_inhabitant
      end

      return {
        'hits' => response['hits']['hits'].map{ |h| h['_source'] },
        'aggregations' => response['aggregations']
      }
    end

    def self.budget_line_query(options, only_municipalities=false)
      GobiertoBudgets::SearchEngine.client.search(index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: budget_line_query_body(options, only_municipalities), _source: ["population", "ine_code", "organization_id", "amount", "amount_per_inhabitant"])
    end

    def self.budget_line_query_body(options, only_municipalities=false)
      terms = [
        { term: { year: options[:year] } },
        { term: { kind: options[:kind] } },
        { term: { code: options[:code] } },
        { term: { type: options[:area_name] } },
      ]

      places_restriction = GobiertoBudgets::PlaceSet.new(places_collection: options[:places_collection])

      permitted_organizations = []

      if options[:filters].present?
        population_filter = options[:filters][:population]
        total_filter = options[:filters][:total]
        per_inhabitant_filter = options[:filters][:per_inhabitant]
        aarr_filter = options[:filters][:aarr] if options[:filters][:aarr] != 'undefined'
      end

      if (population_filter && (population_filter[:from].to_i > GobiertoBudgets::Population::FILTER_MIN || population_filter[:to].to_i < GobiertoBudgets::Population::FILTER_MAX))
        reduced_filter = { population: population_filter }
        reduced_filter.merge!(aarr: aarr_filter) if aarr_filter
        results, total_elements = GobiertoBudgets::Population.for_ranking(options[:year], 0, nil, options[:places_collection], reduced_filter)
        places_restriction.restrict(
          ine_codes: results.map { |r| r["ine_code"] }.compact_blank,
          organization_ids: results.map { |r| r["organization_id"] }.compact_blank
        )
      end

      append_ine_codes(terms, places_restriction.ine_codes)
      append_organization_ids(terms, places_restriction.organization_ids + places_restriction.associated_entity_ids)

      if total_filter && (
        total_filter[:from].to_i > GobiertoBudgets::BudgetTotal::TOTAL_FILTER_MIN ||
        total_filter[:to].to_i < GobiertoBudgets::BudgetTotal::TOTAL_FILTER_MAX
      )
        terms << {
          range: {
            amount: { gte: total_filter[:from].to_i, lte: total_filter[:to].to_i }
          }
        }
      end

      if per_inhabitant_filter && (
        per_inhabitant_filter[:from].to_i > GobiertoBudgets::BudgetTotal::PER_INHABITANT_FILTER_MIN ||
        per_inhabitant_filter[:to].to_i < GobiertoBudgets::BudgetTotal::PER_INHABITANT_FILTER_MAX
      )
        terms << {
          range: {
            amount_per_inhabitant: { gte: per_inhabitant_filter[:from].to_i, lte: per_inhabitant_filter[:to].to_i }
          }
        }
      end

      terms << { term: { autonomy_id: aarr_filter } }  unless aarr_filter.blank?
      terms << { exists: { field: "ine_code" } } unless !only_municipalities || options[:places_collection].present? && options[:places_collection] != :ine

      must_not_terms = []
      must_not_terms.push({exists: { field: 'functional_code'}})
      must_not_terms.push({exists: { field: 'custom_code'}})


      query = {
        sort: [ { options[:variable].to_sym => { order: 'desc' } } ],
        query: {
          bool: {
            must: terms
          }.merge(must_not_terms.present? ? { must_not: must_not_terms } : {})
        },
        size: 10_000
      }

      query.merge!(size: options[:per_page]) if options[:per_page].present?
      query.merge!(from: options[:offset]) if options[:offset].present?
      query
    end

    def self.find(options)
      return self.search(options)['hits'].detect{|h| h['code'] == options[:code] }
    end

    def self.for_ranking(options, only_municipalities=false)
      response = budget_line_query(options, only_municipalities)
      if results = response['hits']['hits']
        return results.map{|h| h['_source']}, response['hits']['total']['value']
      else
        return [], 0
      end
    end

    def self.place_position_in_ranking(options, value:, only_municipalities: false)
      id = %w{organization_id year code kind area_name}.map {|f| options[f.to_sym]}.join('/')
      position, total_elements = GobiertoBudgets::SearchEngine.ranking_position(
        index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
        query: budget_line_query_body(options, only_municipalities)[:query],
        field: options[:variable],
        id:,
        value:
      )
      return position || 0, total_elements
    end

    def self.compare(options)
      terms = [{term: { level: options[:level] }},
               {term: { kind: options[:kind] }},
               {term: { year: options[:year] }},
               {term: { type: options[:type] }}
              ]

      terms << {terms: { organization_id: options[:organization_ids] }} if options[:organization_ids].present?
      terms << {terms: { ine_code: options[:ine_codes] }} if options[:ine_codes].present?
      terms << {term: { parent_code: options[:parent_code] }} if options[:parent_code].present?
      terms << {term: { code: options[:code] }} if options[:code].present?

      query = {
        sort: [
          { code: { order: 'asc' } },
          { ine_code: { order: 'asc' }}
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query
      response['hits']['hits'].map{ |h| h['_source'] }
    end

    def self.compare_with_ancestors(options)
      terms = [{term: { kind: options[:kind] }},
                {term: { year: options[:year] }},
                {term: { type: options[:type] }},
                {range: { level: { lte: options[:level].to_i } }},
                {bool: {
                  should: [
                    {wildcard: { code: "#{options[:parent_code][0]}*" }},
                    {term: { parent_code: '' }}
                    ]
                  }
                }]

      terms << {terms: { organization_id: options[:organization_ids] }} if options[:organization_ids].present?
      terms << {terms: { ine_code: options[:ine_codes] }} if options[:ine_codes].present?
      query = {
        sort: [
          { code: { order: 'asc' } },
          { organization_id: { order: 'asc' }}
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query
      response['hits']['hits'].map{ |h| h['_source'] }
    end

    # Codes of the given budget lines that have children, with one query per level
    def self.codes_with_children(budget_lines, area)
      budget_lines.group_by { |budget_line| budget_line['level'].to_i }.each_with_object(Set.new) do |(level, lines), codes|
        conditions = { level: level + 1, type: area }
        conditions.merge! lines.first.symbolize_keys.slice(:ine_code, :kind, :year, :organization_id).compact_blank

        codes.merge(search(conditions)['hits'].map { |child| child['parent_code'] })
      end
    end

    def self.top_differences(options)
      terms = [{term: { kind: options[:kind] }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { organization_id: options[:organization_id] }} if options[:organization_id].present?
      terms << {term: { ine_code: options[:ine_code] }} if options[:ine_code].present?
      terms << {term: { code: options[:code] }} if options[:code].present?
      terms << {term: { type: options[:type] || 'economic' }}

      query = {
        sort: [
          { code: { order: 'asc' } }
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 10_000
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query

      planned_results = response['hits']['hits'].map{ |h| h['_source'] }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, body: query

      executed_results = response['hits']['hits'].map{ |h| h['_source'] }

      results = {}
      planned_results.each do |p|
        if p["amount"].to_f.positive? && (e = executed_results.detect{|e| e['code'] == p['code']})
          results[p['code']] = [p['amount'], e['amount'], ((e['amount'].to_f - p['amount'].to_f)/p['amount'].to_f) * 100]
        end
      end

      return results.sort{ |b, a| a[1][2] <=> b[1][2] }[0..15], results.sort{ |a, b| a[1][2] <=> b[1][2] }[0..15]
    end

    def self.top_values(options)
      terms = [{term: { kind: GobiertoBudgets::BudgetLine::INCOME }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { ine_code: options[:ine_code] }}
      terms << {term: { type: 'economic' }}

      query = {
        sort: [
          { amount: { order: 'desc' } }
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 5
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query

      income_entries = response['hits']['hits'].map{ |h| h['_source'] }

      terms = [{term: { kind: GobiertoBudgets::BudgetLine::EXPENSE }}, {term: { year: options[:year] }}, {term: { level: 3 }}]
      terms << {term: { ine_code: options[:ine_code] }}
      terms << {term: { type: 'functional' }}

      query = {
        sort: [
          { amount: { order: 'desc' } }
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 5
      }

      response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query

      expense_entries = response['hits']['hits'].map{ |h| h['_source'] }

      return income_entries, expense_entries
    end

    def to_param
      {place_id: place_id, year: year, code: code, area_name: area_name, kind: kind}
    end

    def place
      if place_id
        GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find_in_all_collections(place_id)
      end
    end

    def category
      area = area_name == 'economic' ? EconomicArea : FunctionalArea
      area.all_items[self.kind][self.code]
    end
  end
end
