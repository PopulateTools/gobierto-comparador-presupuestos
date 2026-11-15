# frozen_string_literal: true

module GobiertoBudgets
  class BudgetTotal

    include CommonQueryBehavior

    TOTAL_FILTER_MIN = 0
    TOTAL_FILTER_MAX = 5_000_000_000
    PER_INHABITANT_FILTER_MIN = 0
    PER_INHABITANT_FILTER_MAX = 20_000
    BUDGETED = "B"
    EXECUTED = "E"

    def self.budgeted_for(organization_id, year, kind = BudgetLine::EXPENSE)
      BudgetTotal.for(organization_id, year, BudgetTotal::BUDGETED, kind)
    end

    def self.execution_for(organization_id, year, kind = BudgetLine::EXPENSE)
      BudgetTotal.for(organization_id, year, BudgetTotal::EXECUTED, kind)
    end

    def self.for(organization_id, year, b_or_e = BudgetTotal::BUDGETED, kind = BudgetLine::EXPENSE)
      return for_places(organization_id, year, kind) if organization_id.is_a?(Array)

      index = (b_or_e == BudgetTotal::EXECUTED) ? SearchEngineConfiguration::TotalBudget.index_executed : SearchEngineConfiguration::TotalBudget.index_forecast
      id = [organization_id, year, kind, SearchEngineConfiguration::TotalBudget.type].join("/")

      result = SearchEngine.client.get(index: index, id: id)
      result["_source"]["amount"].to_f
    rescue ::Elasticsearch::Transport::Transport::Errors::NotFound => e
      nil
    end

    def self.budget_evolution_for(organization_id, b_or_e = BudgetTotal::BUDGETED, kind = BudgetLine::EXPENSE)
      query = {
        sort: [
          { year: { order: 'asc' } }
        ],
        query: {
          bool: {
            must: [
              {term: {organization_id: organization_id}},
              {term: {kind: kind}},
              {term: {type: SearchEngineConfiguration::TotalBudget.type}}
            ]
          }
        },
        size: 10_000
      }

      index = index = (b_or_e == BudgetTotal::EXECUTED) ? SearchEngineConfiguration::TotalBudget.index_executed : SearchEngineConfiguration::TotalBudget.index_forecast

      response = SearchEngine.client.search index: index, body: query
      response['hits']['hits'].map{ |h| h['_source'] }
    end

    def self.for_places(organizations_ids, year, kind = BudgetLine::EXPENSE)
      terms = [
        { terms: { organization_id: organizations_ids } },
        { term: { year: year } },
        { term: { kind: kind } },
        { term: { type: SearchEngineConfiguration::TotalBudget.type } }
      ]

      query = {
        query: {
          bool: {
            must: terms
          }
        },
        size: 10000
      }

      response = SearchEngine.client.search(
        index: SearchEngineConfiguration::TotalBudget.index_forecast,
        body: query,
        filter_path: "hits.hits._source",
        _source: ["amount", "ine_code", "organization_id", "amount_per_inhabitant"]
      )

      if response.empty?
        {}
      else
        response['hits']['hits'].map{ |h| h['_source'] }
      end
    end

    def self.for_ranking(year, variable, kind, offset, per_page, places_collection, filters = {})
      response = budget_total_ranking_query(year: year, variable: variable, kind: kind, filters: filters, offset: offset, per_page: per_page, places_collection: places_collection)
      if response.empty?
        return [], 0
      end
      total_elements = response['hits']['total']['value']
      results = response['hits']['hits']
      if results && results.any?
        results = results.map{|h| h['_source']}
      else
        results = []
      end
      return results, total_elements
    end

    def self.budget_total_ranking_query(options)
      terms =  [{term: { year: options[:year]}}]
      terms << {term: { kind: options[:kind]}} if options[:kind].present?
      terms << { exists: { field: "ine_code" } } unless options[:places_collection].present? && options[:places_collection] != :ine # Ensure only city councils appear

      places_restriction = GobiertoBudgets::PlaceSet.new(places_collection: options[:places_collection])

      if options[:filters].present?
        population_filter =  options[:filters][:population]
        total_filter = options[:filters][:total]
        per_inhabitant_filter = options[:filters][:per_inhabitant]
        aarr_filter = options[:filters][:aarr] if options[:filters][:aarr] != 'undefined'
      end

      if (population_filter && (population_filter[:from].to_i > Population::FILTER_MIN || population_filter[:to].to_i < Population::FILTER_MAX))
        reduced_filter = {population: population_filter}
        reduced_filter.merge!(aarr: aarr_filter) if aarr_filter
        results,total_elements = Population.for_ranking(options[:year], 0, nil, options[:places_collection], reduced_filter)

        places_restriction.restrict(
          ine_codes: results.map { |r| r["ine_code"] }.compact_blank,
          organization_ids: results.map { |r| r["organization_id"] }.compact_blank
        )
      end

      append_ine_codes(terms, places_restriction.ine_codes)
      append_organization_ids(terms, places_restriction.organization_ids)

      if (total_filter && (total_filter[:from].to_i > BudgetTotal::TOTAL_FILTER_MIN || total_filter[:to].to_i < BudgetTotal::TOTAL_FILTER_MAX))
        terms << {range: { amount: { gte: total_filter[:from].to_i, lte: total_filter[:to].to_i} }}
      end

      if (per_inhabitant_filter && (per_inhabitant_filter[:from].to_i > BudgetTotal::PER_INHABITANT_FILTER_MIN || per_inhabitant_filter[:to].to_i < BudgetTotal::PER_INHABITANT_FILTER_MAX))
        terms << {range: { amount_per_inhabitant: { gte: per_inhabitant_filter[:from].to_i, lte: per_inhabitant_filter[:to].to_i} }}
      end

      terms << {term: { autonomy_id: aarr_filter }} unless aarr_filter.blank?
      terms << {term: {type: SearchEngineConfiguration::TotalBudget.type }}

      query = {
        sort: [
          { options[:variable].to_sym => { order: 'desc' } }
        ],
        query: {
          bool: {
            must: terms
          }
        },
        size: 10000
      }
      query.merge!(size: options[:per_page]) if options[:per_page].present?
      query.merge!(from: options[:offset]) if options[:offset].present?
      query.merge!(_source: false) if options[:to_rank]

      index = SearchEngineConfiguration::TotalBudget.index_forecast
      if options[:executed]
        index = SearchEngineConfiguration::TotalBudget.index_executed
      end

      SearchEngine.client.search index: index,
        body: query,
        filter_path: "hits.hits._source,hits.total",
        _source: ["amount", "ine_code", "organization_id", "amount_per_inhabitant"]
    end
  end
end
