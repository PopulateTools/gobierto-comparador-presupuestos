# frozen_string_literal: true

module GobiertoBudgets
  module Api
    class DataController < ApplicationController

      include GobiertoBudgets::ApplicationHelper
      include GobiertoBudgets::BudgetLineWidgetHelper

      before_action :set_current_organization
      attr_accessor :current_organization

      caches_action(
        :total_budget,
        :total_budget_execution,
        :population,
        :total_budget_per_inhabitant,
        :lines,
        :budget,
        :budget_execution,
        :budget_per_inhabitant,
        :budget_percentage_over_total,
        :debt,
        :budget_percentage_previous_year,
        :ranking,
        :budget_execution_deviation,
        cache_path: -> { { locale: I18n.locale, places_collection: places_collection_key } }
      )

      def total_budget
        year = params[:year].to_i
        total_budget_data = total_budget_data(year, 'amount')
        total_budget_data_previous_year = total_budget_data(year - 1, 'amount', false)
        position = total_budget_data[:position].to_i
        sign = sign(total_budget_data[:value], total_budget_data_previous_year[:value])

        respond_to do |format|
          format.json do
            render json: {
              title: t('.total_expenses'),
              sign: sign,
              value: format_currency(total_budget_data[:value]),
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data[:value], total_budget_data_previous_year[:value]), precision: 2),
              ranking_position: position,
              ranking_total_elements: helpers.number_with_precision(total_budget_data[:total_elements], precision: 0),
              ranking_url: locations_ranking_path(
                year,
                "G",
                "economic",
                "amount",
                page: GobiertoBudgets::Ranking.page_from_position(position),
                ine_code: current_organization.place_id
              )
            }.to_json
          end
        end
      end

      def population
        year = params[:year].to_i
        no_data_this_year = nil
        population_data = GobiertoBudgets::Population.ranking_hash_for(params[:ine_code], year, places_collection: params[:places_collection])
        if population_data[:value].nil?
          year -= 1
          population_data = GobiertoBudgets::Population.ranking_hash_for(params[:ine_code], year, places_collection: params[:places_collection])
          no_data_this_year = year
        end
        population_data_previous_year = GobiertoBudgets::Population.ranking_hash_for(params[:ine_code], year - 1, places_collection: params[:places_collection])
        position = population_data[:position]
        sign = sign(population_data[:value], population_data_previous_year[:value])

        respond_to do |format|
          format.json do
            render json: {
              title: t('.population'),
              sign: sign,
              value: helpers.number_with_delimiter(population_data[:value], precision: 0, strip_insignificant_zeros: true),
              delta_percentage: helpers.number_with_precision(delta_percentage(population_data[:value], population_data_previous_year[:value]), precision: 2),
              ranking_position: position,
              ranking_total_elements: helpers.number_with_precision(population_data[:total_elements], precision: 0),
              ranking_url: gobierto_budgets_population_ranking_path(year, GobiertoBudgets::Ranking.page_from_position(position), ine_code: params[:ine_code]),
              no_data_this_year: no_data_this_year
            }.to_json
          end
        end
      end

      def total_budget_per_inhabitant
        year = params[:year].to_i
        total_budget_data = total_budget_data(year, 'amount_per_inhabitant')
        total_budget_data_previous_year = total_budget_data(year - 1, 'amount_per_inhabitant', false)
        position = total_budget_data[:position].to_i
        sign = sign(total_budget_data[:value], total_budget_data_previous_year[:value])

        respond_to do |format|
          format.json do
            render json: {
              title: t('.expenses_per_inhabitant'),
              sign: sign,
              value: helpers.number_to_currency(total_budget_data[:value], precision: 0, strip_insignificant_zeros: true),
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data[:value], total_budget_data_previous_year[:value]), precision: 2),
              ranking_position: position,
              ranking_total_elements: helpers.number_with_precision(total_budget_data[:total_elements], precision: 0),
              ranking_url: locations_ranking_path(
                year,
                'G',
                'economic',
                'amount_per_inhabitant',
                nil,
                GobiertoBudgets::Ranking.page_from_position(position),
                ine_code: current_organization.ine_code
              )
            }.to_json
          end
        end
      end

      def lines
        data_line = GobiertoBudgets::Data::Lines.new(
          organization: current_organization,
          year: params[:year],
          what: params[:what],
          kind: params[:kind],
          code: params[:code],
          area: params[:area]
        )

        respond_lines_to_json data_line
      end

      def compare
        @organizations = get_places params[:ine_codes], places_collection: params[:places_collection]

        data_line = GobiertoBudgets::Data::Lines.new(
          organization: @organizations,
          year: params[:year],
          what: params[:what],
          kind: params[:kind],
          code: params[:code],
          area: params[:area]
        )

        respond_lines_to_json data_line
      end

      def budget
        data_hash = amount_summary(default_budget_line_params)

        respond_to do |format|
          format.json do
            render(json: data_hash.to_json)
          end
        end
      end

      def budget_execution
        @year = params[:year].to_i
        @area = params[:area]
        @kind = params[:kind]
        @code = params[:code]

        @category_name = @kind == 'G' ? t('.expense_planned_vs_executed') : t('.income_planned_vs_executed')

        budget_executed = budget_data_executed(@year, 'amount')
        budget_planned = budget_data(
          year: @year,
          kind: @kind,
          area: @area,
          code: @code,
          field: "amount"
        )
        sign = sign(budget_executed[:value], budget_planned[:value])

        respond_to do |format|
          format.json do
            render json: {
              title: @category_name,
              sign: sign,
              value: format_currency(budget_executed[:value]),
              delta_percentage: helpers.number_with_precision(delta_percentage(budget_executed[:value], budget_planned[:value]), precision: 2),
            }.to_json
          end
        end
      end

      def budget_per_inhabitant
        data_hash = budget_per_inhabitant_summary(default_budget_line_params)

        respond_to do |format|
          format.json do
            render(json: data_hash.to_json)
          end
        end
      end

      def budget_percentage_previous_year
        @year = params[:year].to_i
        @area = params[:area]
        @kind = params[:kind]
        @code = params[:code]

        begin
          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            id: [current_organization.id, @year, @code, @kind, @area].join('/')
          )

          amount = result['_source']['amount'].to_f

          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            id: [current_organization.id, @year - 1, @code, @kind, @area].join('/')
          )

          amount_previous_year = result['_source']['amount'].to_f

          percentage = delta_percentage(amount, amount_previous_year)
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          percentage = 0
        end

        respond_to do |format|
          format.json do
            render json: {
              title: t('.percentage_previous_year'),
              value: "#{helpers.number_with_precision(percentage, precision: 2, strip_insignificant_zeros: true)}%",
              sign: sign(percentage)
            }.to_json
          end
        end
      end

      def budget_percentage_over_total
        data_hash = percentage_over_total_summary(default_budget_line_params)

        respond_to do |format|
          format.json do
            render(json: data_hash.to_json)
          end
        end
      end

      def ranking
        @year = params[:year].to_i
        @area = params[:area]
        @kind = params[:kind]
        @var = params[:variable]
        @code = params[:code]
        @places_collection = params[:places_collection] || :ine

        only_municipalities = (params[:only_municipalities] == "true")

        offset = 0
        max_results = 5

        if @code.present?
          @variable = (@var == 'amount') ? 'amount' : 'amount_per_inhabitant'

          opts = {
            year: @year,
            area_name: @area,
            kind: @kind,
            code: @code,
            variable: @variable,
            places_collection: @places_collection,
            offset: 0,
            per_page: 5
          }

          results, _total_elements = GobiertoBudgets::BudgetLine.for_ranking(opts, only_municipalities)
        else
          @variable = (@var == 'amount') ? 'amount' : 'amount_per_inhabitant'
          results, _total_elements = GobiertoBudgets::BudgetTotal.for_ranking(@year, @variable, @kind, offset, max_results, @places_collection)
        end

        top = results.first
        title = ranking_title(@variable, @year, @kind, @code, @area)

        data = if results.blank?
                {}
              else
                {
                  title: title,
                  top_place_name: place_name(top["organization_id"], places_collection: @places_collection),
                  top_amount: helpers.number_to_currency(top[@variable], precision: 0, strip_insignificant_zeros: true),
                  ranking_path: locations_ranking_path(@year, @kind, @area, @var, @code),
                  ranking_url: locations_ranking_url(@year, @kind, @area, @var, @code),
                  twitter_share: ERB::Util.url_encode(twitter_share(title, locations_ranking_url(@year, @kind, @area, @var, @code))),
                  top_5: results.map { |r| { place_name: place_name(r["organization_id"], places_collection: @places_collection) } }
                }
              end

        respond_to do |format|
          format.json do
            render json: data.to_json
          end
        end
      end

      def total_budget_execution
        year = params[:year].to_i
        total_budget_data_planned = total_budget_data(year, 'amount', false)
        total_budget_data_executed = total_budget_data_executed(year, 'amount')
        diff = total_budget_data_executed[:value] - total_budget_data_planned[:value] rescue ""
        sign = sign(total_budget_data_executed[:value], total_budget_data_planned[:value])
        diff = format_currency(diff) if diff.is_a?(Float)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.planned_vs_executed'),
              sign: sign,
              delta_percentage: helpers.number_with_precision(delta_percentage(total_budget_data_executed[:value], total_budget_data_planned[:value]), precision: 2),
              value: diff
            }.to_json
          end
        end
      end

      def debt
        year = params[:year].to_i

        no_data_this_year = false
        debt_year = get_debt(year, current_organization.id)
        if debt_year[:value].nil?
          year -= 1
          debt_year = get_debt(year, current_organization.id)
          no_data_this_year = year
        end
        debt_previous_year = get_debt(year - 1, current_organization.id)
        sign = sign(debt_year, debt_previous_year)

        respond_to do |format|
          format.json do
            render json: {
              title: t('.debt'),
              sign: nil,
              delta_percentage: helpers.number_with_precision(delta_percentage(debt_previous_year[:value], debt_year[:value]), precision: 2),
              value: format_currency(debt_year[:value]),
              no_data_this_year: no_data_this_year,
              ranking_position: debt_year[:position],
              ranking_total_elements: helpers.number_with_precision(debt_year[:total_elements], precision: 0),
              ranking_url: nil
            }.to_json
          end
        end
      end

      def municipalities_population
        year = params[:year].to_i

        terms = [
          {term: { year: year }},
          {term: { type: GobiertoBudgets::SearchEngineConfiguration::Data.type_population}}
        ]

        query = {
          sort: [
            { ine_code: { order: 'asc' } }
          ],
          query: {
            bool: {
              must: terms
            }
          },
          size: 10_000
        }

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::Data.index, body: query

        result = response['hits']['hits'].map{ |h| h['_source'] }

        respond_to do |format|
          format.json do
            render json: result.to_json
          end
          format.csv do
            csv =  CSV.generate do |csv|
              csv << result.first.keys
              result.each do |row|
                csv << row.values
              end
            end
            send_data csv, filename: "population-#{year}.csv"
          end
        end
      end

      def municipalities_debt
        year = params[:year].to_i

        terms = [
          {term: { year: year }},
          {term: { type: GobiertoBudgets::SearchEngineConfiguration::Data.type_debt}}
        ]

        query = {
          sort: [
            { ine_code: { order: 'asc' } }
          ],
          query: {
            bool: {
              must: terms
            }
          },
          size: 10_000
        }

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::Data.index, body: query
        result = response['hits']['hits'].map{ |h| h['_source'].merge({'value' => h['_source']['value']*1_000}) }

        respond_to do |format|
          format.json do
            render json: result.to_json
          end
          format.csv do
            csv =  CSV.generate do |csv|
              csv << result.first.keys
              result.each do |row|
                csv << row.values
              end
            end
            send_data csv, filename: "debt-#{year}.csv"
          end
        end
      end

      def budgets
        year = params[:year].to_i
        kind = params[:kind]
        area_name = params[:area]

        query = {
          sort: [
            { 'code' => { order: 'asc' } }
          ],
          query: {
            bool: {
              must: [
                {term: { year: year }},
                {term: { organization_id: current_organization.id }},
                {term: { kind: kind }},
                {term: { type: area_name }}
              ]
            }
          },
          size: 10_000
        }
        area = area_name == 'economic' ? EconomicArea : FunctionalArea

        response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, body: query
        items = response['hits']['hits'].map do |h|
              h['_source'].merge({category: area.all_items[kind][h['_source']['code']]})
            end
        respond_to do |format|
          format.json do
            render json: items.to_json
          end
        end
      end

      def budget_execution_deviation
        year = params[:year].to_i
        kind = params[:kind]
        organization_id = current_organization.id

        total_budgeted = GobiertoBudgets::BudgetTotal.budgeted_for(organization_id, year, kind)
        total_executed = GobiertoBudgets::BudgetTotal.execution_for(organization_id, year, kind)

        deviation = total_executed - total_budgeted
        deviation_percentage = helpers.number_with_precision(delta_percentage(total_executed, total_budgeted), precision: 2)
        up_or_down = sign(total_executed, total_budgeted)
        evolution = deviation_evolution(organization_id, kind)

        heading = I18n.t("gobierto_budgets.api.data.#{kind}_deviation", year: year).capitalize
        respond_to do |format|
          format.json do
            render json: {
              deviation_heading: heading,
              deviation_summary: deviation_message(kind, up_or_down, deviation_percentage, deviation),
              deviation_percentage: deviation_percentage,
              "#{kind}": {
                total_budgeted: format_currency(total_budgeted),
                total_executed: format_currency(total_executed),
                evolution: evolution,
                evolution_to_s: evolution.to_json
              }
            }.to_json
          end
        end
      end

      private

      def get_debt(year, organization_id)
        id = "#{organization_id}/#{year}/#{GobiertoBudgets::SearchEngineConfiguration::Data.type_debt}"

        terms = []
        terms.push({ term: { year: year } })
        terms.push({term: { type: GobiertoBudgets::SearchEngineConfiguration::Data.type_debt }})

        if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
          organizations_ids = GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope
          terms << {terms: { organization_id: organizations_ids.compact }} if organizations_ids.any?
        end

        query = {
          query: {
            bool: {
              must: terms
            }
          },
          size: 10_000,
          _source: false
        }

        value = nil
        begin
          response = GobiertoBudgets::SearchEngine.client.search index: GobiertoBudgets::SearchEngineConfiguration::Data.index, body: query
          debts = response['hits']['hits'].map{|h| h['_id']}
          position = debts.index(id) + 1 rescue 0

          value = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::Data.index, id: id
          value = value['_source']['value']
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          debts = []
          position = nil
        end

        return {
          value: value,
          position: position,
          total_elements: debts.length
        }
      end

      def ranking_title(variable, year, kind, code, area_name)
        title = ["Top"]
        title << ((kind == 'G') ? I18n.t('common.expenses') : I18n.t('common.incomes'))
        title << ((variable == 'total_budget' or variable == 'amount') ? I18n.t('common.totals') : I18n.t('common.per_inhabitant'))
        title << "en #{budget_line_denomination(area_name, code, kind)}" if code.present?
        title << "en #{year}"
        title.join(' ')
      end

      def budget_data_executed(year, field)
        id = "#{current_organization.id}/#{year}/#{@code}/#{@kind}/#{@area}"

        begin
          value = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_executed, id: id
          value = value['_source'][field]
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          value = nil
        end

        return {
          value: value
        }
      end

      def total_budget_data(year, field, ranking = true)
        terms = [
          { term: { year: year } },
          { term: { kind: GobiertoBudgets::BudgetLine::EXPENSE } },
          { term: { type: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type } }
        ]

        organizations_ids = if GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
                              GobiertoBudgets::SearchEngineConfiguration::Scopes.organizations_scope
                            elsif params[:places_collection].present?
                              GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.collection_organization_ids(params[:places_collection])
                            end
        terms << { terms: { organization_id: organizations_ids.compact } } if organizations_ids.present?

        body = {
          sort: [
            { field.to_sym => { order: 'desc' } }
          ],
          query: {
            bool: {
              must: terms
            }
          },
          size: 10_000,
          _source: false
        }

        id = "#{current_organization.id}/#{year}/#{BudgetLine::EXPENSE}/#{GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type}"

        if ranking
          response = GobiertoBudgets::SearchEngine.client.search(
            index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast,
            body: body
          )
          buckets = response['hits']['hits'].map{|h| h['_id']}
          position = buckets.index(id) + 1 rescue 0
        else
          buckets = []
          position = 0
        end

        begin
          value = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast,
            id: id
          )
          value = value['_source'][field]
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          value = 0
        end

        return {
          value: value,
          position: position,
          total_elements: buckets.length
        }
      end

      def total_budget_data_executed(year, field)
        id = "#{current_organization.id}/#{year}/#{BudgetLine::EXPENSE}/#{GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type}"

        begin
          value = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_executed, id: id
          value = value['_source'][field]
          value = nil if value == 0
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          value = nil
        end

        return {
          value: value
        }
      end

      def deviation_message(kind, up_or_down, percentage, diff)
        percentage = percentage.to_s.gsub('-', '')
        diff = format_currency(diff, true)
        final_message = if (kind == GobiertoBudgets::BudgetLine::INCOME)
          up_or_down == "sign-up" ? I18n.t("gobierto_budgets.api.data.income_up", percentage: percentage, diff: diff) : I18n.t("gobierto_budgets.api.data.income_down", percentage: percentage, diff: diff)
        else
          up_or_down == "sign-up" ? I18n.t("gobierto_budgets.api.data.expense_up", percentage: percentage, diff: diff) : I18n.t("gobierto_budgets.api.data.expense_down", percentage: percentage, diff: diff)
        end
        final_message
      end

      def deviation_evolution(organization_id, kind)
        response_budgeted = GobiertoBudgets::BudgetTotal.budget_evolution_for(organization_id, GobiertoBudgets::BudgetTotal::BUDGETED, kind)
        response_executed = GobiertoBudgets::BudgetTotal.budget_evolution_for(organization_id, GobiertoBudgets::BudgetTotal::EXECUTED, kind)

        response_budgeted.map do |budgeted_result|
          year = budgeted_result['year']
          total_budgeted = budgeted_result['amount']
          total_executed = response_executed.select {|te| te['year'] == year }.first.try(:[],'amount')
          next unless total_executed.present?

          deviation = delta_percentage(total_executed, total_budgeted)
          {
            year: year,
            deviation: helpers.number_with_precision(deviation, precision: 2, separator: '.').to_f
          }
        end.reject(&:nil?)
      end

      def get_places(ine_codes, places_collection: :ine)
        ine_codes.split(":").map { |code| Organization.new(organization_id: code, places_collection:) }
      end

      def respond_lines_to_json(data_line)
        respond_to do |format|
          format.json do
            render json: data_line.generate_json
          end
        end
      end

      def set_current_organization
        return unless params[:ine_code] || params[:organization_slug]

        @current_organization = if params[:ine_code]
                                  Organization.new(organization_id: params[:ine_code], places_collection: params[:places_collection])
                                else
                                  Organization.new(slug: params[:organization_slug], places_collection: params[:places_collection])
                                end
        render_404 and return if @current_organization.nil? || (@current_organization.place.nil? && @current_organization.associated_entity.nil?)
      end

      def default_budget_line_params
        params.slice(:area, :kind, :code)
              .merge(year: params[:year].to_i)
      end

    end
  end
end
