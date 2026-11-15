# frozen_string_literal: true

require "csv"

module GobiertoBudgets
  # Exports the municipalities budgets as the CSV files loaded by the gobierto-etl-datos
  # presupuestos_municipales pipeline into the indicadores_presupuestos_municipales and
  # presupuestos_municipales datasets of datos.gobierto.es, which feed the maps page.
  class IndicatorsExport
    INDICATORS_HEADER = %w(year place_id gasto_por_habitante gasto_total planned_vs_executed population debt).freeze
    PLANNED_BUDGETS_HEADER = %w(year place_id area kind amount code amount_per_inhabitant).freeze
    AREA_CODES = { BudgetLine::ECONOMIC => "e", BudgetLine::FUNCTIONAL => "f" }.freeze
    SCROLL_SIZE = 5_000
    SCROLL_TIMEOUT = "5m"

    def write_indicators(io)
      planned = totals(SearchEngineConfiguration::TotalBudget.index_forecast)
      executed = totals(SearchEngineConfiguration::TotalBudget.index_executed)
      population = data_values(SearchEngineConfiguration::Data.type_population)
      debt = data_values(SearchEngineConfiguration::Data.type_debt)

      csv = CSV.new(io)
      csv << INDICATORS_HEADER
      years.each do |year|
        place_ids.each do |place_id|
          planned_total = value_since(planned, place_id, year, :amount)
          executed_total = value_since(executed, place_id, year, :amount)

          csv << [
            year,
            place_id,
            value_since(planned, place_id, year, :amount_per_inhabitant),
            planned_total,
            planned_vs_executed(planned_total, executed_total),
            value_in_year_or_previous(population, place_id, year)&.to_i,
            value_in_year_or_previous(debt, place_id, year)
          ]
        end
      end
    end

    def write_planned_budgets(io)
      csv = CSV.new(io, force_quotes: true)
      csv << PLANNED_BUDGETS_HEADER
      AREA_CODES.each do |area, area_code|
        each_document(SearchEngineConfiguration::BudgetLine.index_forecast, planned_budget_lines_query(area)) do |line|
          csv << [line["year"], line["ine_code"], area_code, line["kind"], line["amount"], line["code"].to_s, line["amount_per_inhabitant"]]
        end
      end
    end

    private

    def years
      SearchEngineConfiguration::Year.all
    end

    def place_ids
      @place_ids ||= GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.collection_organization_ids(:ine).map(&:to_s)
    end

    # Expense totals of each place and year: { place_id => { year => { amount:, amount_per_inhabitant: } } }
    def totals(index)
      query = { bool: { must: [{ term: { type: SearchEngineConfiguration::TotalBudget.type } }, { term: { kind: BudgetLine::EXPENSE } }] } }

      each_document(index, query).each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |total, totals|
        totals[total["organization_id"].to_s][total["year"].to_i] = {
          amount: total["amount"]&.to_f,
          amount_per_inhabitant: total["amount_per_inhabitant"]&.to_f
        }
      end
    end

    # Values of a data type of each place and year: { place_id => { year => value } }
    def data_values(type)
      query = { bool: { must: [{ term: { type: } }] } }

      each_document(SearchEngineConfiguration::Data.index, query).each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |document, values|
        values[document["organization_id"].to_s][document["year"].to_i] = document["value"]&.to_f
      end
    end

    # Value of the year or, when the place has no value or a zero one, of the last previous year with a value.
    def value_since(totals, place_id, year, attribute)
      year.downto(SearchEngineConfiguration::Year.first) do |previous_year|
        value = totals.dig(place_id, previous_year, attribute)
        return value if value.present? && value != 0.0
      end
      nil
    end

    def value_in_year_or_previous(values, place_id, year)
      values.dig(place_id, year) || values.dig(place_id, year - 1)
    end

    def planned_vs_executed(planned, executed)
      return if planned.nil? || executed.nil?

      ((executed - planned) / planned * 100).round(2)
    end

    def planned_budget_lines_query(area)
      {
        bool: {
          must: [
            { term: { type: area } },
            { terms: { organization_id: place_ids } },
            { range: { year: { gte: SearchEngineConfiguration::Year.first, lte: SearchEngineConfiguration::Year.last } } }
          ],
          must_not: [{ exists: { field: "functional_code" } }]
        }
      }
    end

    def each_document(index, query)
      return enum_for(:each_document, index, query) unless block_given?

      client = SearchEngine.client
      response = client.search(index:, scroll: SCROLL_TIMEOUT, body: { query:, size: SCROLL_SIZE, sort: ["_doc"] })
      scroll_id = response["_scroll_id"]

      while response["hits"]["hits"].any?
        response["hits"]["hits"].each { |hit| yield hit["_source"] }
        response = client.scroll(body: { scroll_id: }, scroll: SCROLL_TIMEOUT)
        scroll_id = response["_scroll_id"]
      end
    ensure
      client.clear_scroll(body: { scroll_id: }) if scroll_id
    end
  end
end
