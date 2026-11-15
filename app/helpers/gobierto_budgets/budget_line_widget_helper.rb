# frozen_string_literal: true

module GobiertoBudgets
  module BudgetLineWidgetHelper
    extend ActiveSupport::Concern

    include GobiertoBudgets::ApplicationHelper

    MAX_FEATURED_BUDGET_LINE_YEAR_FALLBACK = 8

    private

    def featured_budget_line?
      @code.present?
    end

    def load_budget_lines(params = {})
      calculate_lines

      if params[:allow_year_fallback]
        while @no_data && (@year >= Date.today.year - MAX_FEATURED_BUDGET_LINE_YEAR_FALLBACK)
          @year -= 1
          calculate_lines
        end

        if params[:start_year].present? && params[:start_year] != @year
          redirect_to location_path(current_organization.combined_slug, @year) and return
        end
      end
      load_featured_budget_line
    end

    def calculate_lines
      @income_lines = BudgetLine.search(
        organization_id: current_organization.id,
        level: 1,
        year: @year,
        kind: BudgetLine::INCOME,
        type: GobiertoBudgets::BudgetLine::ECONOMIC
      )

      @expense_lines = GobiertoBudgets::BudgetLine::AREA_NAMES.each_with_object({}) do |type, data|
        data[type] = GobiertoBudgets::BudgetLine.search(organization_id: current_organization.id, level: 1, year: @year, kind: BudgetLine::EXPENSE, type:, recalculate_aggregations: true)
      end

      @area_names_with_expense_data = @expense_lines.select  { |_name, data| data["hits"].present? }.keys
      @expense_area_name = @area_names_with_expense_data.include?(@area_name) ? @area_name : @area_names_with_expense_data.first

      @no_data = @income_lines['hits'].empty? && @expense_area_name.blank?
    end

    def load_featured_budget_line
      @area_name ||= GobiertoBudgets::BudgetLine::FUNCTIONAL
      @kind ||= GobiertoBudgets::BudgetLine::EXPENSE

      results = featured_budget_line_candidates

      @code = results.any? ? results.sample["code"] : nil
    end

    def featured_budget_line_candidates
      GobiertoBudgets::BudgetLine.search(
        kind: @kind,
        year: @year,
        organization_id: @current_organization.id,
        type: @area_name,
        range_hash: {
          level: { gte: 4 },
          amount_per_inhabitant: { gt: 0 }
        }
      )["hits"]
    end

    def default_budget_line_params
      { year: @year, kind: @kind, area: @area_name, code: @code, places_collection: @places_collection }
    end

    def budget_per_inhabitant_summary(options)
      year = options[:year]
      kind = options[:kind]
      area = options[:area]
      code = options[:code]

      title = if kind == "G"
                I18n.t("gobierto_budgets.api.data.budget_per_inhabitant.expenses_per_inhabitant")
              else
                I18n.t("gobierto_budgets.api.data.budget_per_inhabitant.income_per_inhabitant")
              end

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, options)) do
        budget_data = budget_data(options.merge(field: "amount_per_inhabitant"))
        budget_data_previous_year = budget_data_previous_year(options.merge(field: "amount_per_inhabitant"))
        position = budget_data[:position].to_i

        if budget_data_previous_year
          delta_percentage = helpers.number_with_precision(delta_percentage(budget_data[:value], budget_data_previous_year[:value]), precision: 2)
          sign = sign(budget_data[:value], budget_data_previous_year[:value])
        else
          delta_percentage = nil
          sign = nil
        end

        {
          sign: sign,
          title: title,
          value: format_currency(budget_data[:value]),
          delta_percentage: delta_percentage,
          ranking_position: position,
          ranking_total_elements: helpers.number_with_precision(budget_data[:total_elements], precision: 0),
          ranking_url: locations_ranking_path(
            year,
            kind,
            area,
            "amount_per_inhabitant",
            code.parameterize,
            page: GobiertoBudgets::Ranking.page_from_position(position),
            ine_code: current_organization.ine_code
          )
        }
      end
    end

    def amount_summary(options)
      year = options[:year]
      kind = options[:kind]
      area = options[:area]
      code = options[:code]

      category_name = kind == 'G' ? I18n.t('gobierto_budgets.budget_lines.show.expense').capitalize : I18n.t('gobierto_budgets.budget_lines.show.income').capitalize

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, options)) do
        budget_data = budget_data(options.merge(field: "amount"))
        budget_data_previous_year = budget_data_previous_year(options.merge(field: "amount"))
        position = budget_data[:position].to_i

        if budget_data_previous_year
          delta_percentage = helpers.number_with_precision(delta_percentage(budget_data[:value], budget_data_previous_year[:value]), precision: 2)
          sign = sign(budget_data[:value], budget_data_previous_year[:value])
        else
          delta_percentage = nil
          sign = nil
        end

        {
          title: category_name,
          sign: sign,
          value: format_currency(budget_data[:value]),
          delta_percentage: delta_percentage,
          ranking_position: position,
          ranking_total_elements: helpers.number_with_precision(budget_data[:total_elements], precision: 0),
          ranking_url: locations_ranking_path(
            year,
            kind,
            area,
            "amount",
            code.parameterize,
            page: GobiertoBudgets::Ranking.page_from_position(position),
            ine_code: current_organization.ine_code
          )
        }
      end
    end

    def percentage_over_total_summary(options)
      year = options[:year]
      kind = options[:kind]
      area = options[:area]
      code = options[:code]

      Rails.cache.fetch(elasticsearch_query_cache_key(__method__, options)) do
        begin
          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast,
            id: [current_organization.id, year, code, kind, area].join("/")
          )

          amount = result['_source']['amount'].to_f

          result = GobiertoBudgets::SearchEngine.client.get(
            index: GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast,
            id: [current_organization.id, year, BudgetLine::EXPENSE, GobiertoBudgets::SearchEngineConfiguration::TotalBudget.type].join('/')
          )

          total_amount = result['_source']['amount'].to_f

          percentage = (amount.to_f * 100)/total_amount
        rescue Elasticsearch::Transport::Transport::Errors::NotFound
          percentage = 0
        end

        {
          title: I18n.t('gobierto_budgets.featured_budget_lines.show.percentage_over_total'),
          value: "#{helpers.number_with_precision(percentage, precision: 2, strip_insignificant_zeros: true)}%",
          sign: sign(percentage)
        }
      end
    end

    def budget_data_previous_year(options)
      budget_data(options.merge(year: options[:year] - 1, ranking: false))
    rescue Elasticsearch::Transport::Transport::Errors::NotFound
      nil
    end

    def budget_data(options = {})
      year = options[:year]
      kind = options[:kind]
      area = options[:area]
      code = options[:code]
      field = options[:field]
      ranking = options[:ranking] != false

      result = GobiertoBudgets::SearchEngine.client.get index: GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast, id: [current_organization.id, year, code, kind, area].join('/')
      value = result['_source'][field]

      total_elements = 0
      position = 0

      if ranking
        opts = { year: year, code: code, kind: kind, area_name: area, variable: field, place: current_organization&.place, organization_id: current_organization.id, places_collection: options[:places_collection] }
        position, total_elements = BudgetLine.place_position_in_ranking(opts, value:)
      end

      return {
        value: value,
        position: position,
        total_elements: total_elements
      }
    end

    def delta_percentage(value, old_value)
      return "" if value.nil? || old_value.nil? || old_value.to_f == 0

      ((value.to_f - old_value.to_f)/old_value.to_f) * 100
    end

    def elasticsearch_query_cache_key(method_name, options)
      "#{method_name}-#{current_organization.id}-#{options[:year]}-#{options[:kind]}-#{options[:area]}-#{options[:code]}-#{I18n.locale}"
    end

  end
end
