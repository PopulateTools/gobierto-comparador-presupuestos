module GobiertoBudgets
  class PlacesController < GobiertoBudgets::ApplicationController
    include RankingTableHelper
    include GobiertoBudgets::BudgetLineWidgetHelper

    layout :choose_layout
    before_action :set_current_organization, except: [:ranking, :compare, :redirect]
    before_action :get_params
    before_action :solve_income_area_mismatch, except: [:show]
    before_action :admin_user, only: [:intelligence]

    attr_reader :current_organization

    helper_method :current_organization, :featured_budget_line?

    caches_action :show, :execution, :budget, :compare, cache_path: ->(c) { { locale: I18n.locale} }

    def show
      if @year.nil?
        redirect_to location_path(current_organization.combined_slug, SearchEngineConfiguration::Year.last) and return
      end
      load_budget_lines(allow_year_fallback: true, start_year: @year)

      if featured_budget_line?
        @amount_per_inhabitant_summary = budget_per_inhabitant_summary(default_budget_line_params)
        @amount_summary = amount_summary(default_budget_line_params)
        @percentage_over_total_summary = percentage_over_total_summary(default_budget_line_params)
      end

      respond_to do |format|
        format.html
        format.js
      end
    end

    def execution
      @top_possitive_difference_income, @top_negative_difference_income = BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::INCOME,
        type: GobiertoBudgets::BudgetLine::ECONOMIC
      )

      if @top_possitive_difference_income.empty?
        flash[:alert] = t('.no_data', year: @year)
        redirect_to location_execution_path(current_organization.combined_slug, @year.to_i - 1) and return
      end

      @top_possitive_difference_expending_economic, @top_negative_difference_expending_economic = GobiertoBudgets::BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::EXPENSE,
        type: GobiertoBudgets::BudgetLine::ECONOMIC
      )
      @top_possitive_difference_expending_functional, @top_negative_difference_expending_functional = GobiertoBudgets::BudgetLine.top_differences(
        organization_id: current_organization.id,
        year: @year,
        kind: GobiertoBudgets::BudgetLine::EXPENSE,
        type: GobiertoBudgets::BudgetLine::FUNCTIONAL
      )
    end

    def debt_alive
    end

    def budget
      @level = (params[:parent_code].present? ? params[:parent_code].length + 1 : 1)

      options = {
        organization_id: current_organization.id,
        level: @level,
        year: @year,
        kind: @kind,
        type: @area_name
      }

      options[:parent_code] = params[:parent_code] if params[:parent_code].present?

      @budget_lines = GobiertoBudgets::BudgetLine.search(options)

      respond_to do |format|
        format.json do
          data_line = GobiertoBudgets::Data::Treemap.new place: current_organization, year: @year, kind: @kind, type: @area_name, parent_code: params[:parent_code]
          render json: data_line.generate_json
        end
        format.js
      end
    end

    # /places/compare/:slug_list/:year/:kind/:area
    def compare
      @places = get_places params[:slug_list]
      redirect_to locations_compare_path if @places.empty?

      ids = @places.map(&:id)
      @totals = GobiertoBudgets::BudgetTotal.for ids, @year, GobiertoBudgets::BudgetTotal::BUDGETED, @kind
      @population = GobiertoBudgets::Population.for ids, @year, @places_collection
      if @population.empty?
        @population = GobiertoBudgets::Population.for ids, @year - 1, @places_collection
      end

      @compared_level = (params[:parent_code].present? ? params[:parent_code].length + 1 : 1)
      options = { organization_ids: ids, year: @year, kind: @kind, level: @compared_level, type: @area_name }

      if @compared_level > 1
        @budgets_and_ancestors = GobiertoBudgets::BudgetLine.compare_with_ancestors(options.merge(parent_code: params[:parent_code]))
        @budgets_compared = @budgets_and_ancestors.select {|bl| bl['parent_code'] == params[:parent_code]}
        @parent_compared = @budgets_and_ancestors.select {|bl| bl['code'] == params[:parent_code] }
      else
        @budgets_compared = @budgets_and_ancestors = GobiertoBudgets::BudgetLine.compare(options)
      end
    end

    def ranking
      @filters = params[:f]
      @per_page = GobiertoBudgets::Ranking.per_page
      @page = params[:page] ? params[:page].to_i : 1
      render_404 and return if @page <= 0

      @compared_level = params[:code] ? (params[:code].include?('-') ? params[:code].split('-').first.length : params[:code].length) : 0

      @ranking_items = GobiertoBudgets::Ranking.query({
        year: @year,
        variable: @variable,
        page: @page,
        code: @code,
        kind: @kind,
        area_name: @area_name,
        places_collection: @places_collection,
        filters: @filters
      })

      respond_to do |format|
        format.html
        format.js
      end
    rescue GobiertoBudgets::Ranking::OutOfBounds
      respond_to do |format|
        format.html { render_404 }
        format.js { render json: {}, status: :missing }
      end
    end

    def intelligence
    end

    def redirect
      @current_organization = Organization.new(organization_id: params[:ine_code])
      year = params[:year] || ::GobiertoBudgets::SearchEngineConfiguration::Year.last
      if current_organization.present?
        redirect_to location_path(current_organization.combined_slug, year)
      end
    end

    private

    def get_params
      @kind = ( %w{income i}.include?(params[:kind].downcase) ? GobiertoBudgets::BudgetLine::INCOME : GobiertoBudgets::BudgetLine::EXPENSE ) if action_name != 'show' && params[:kind]
      @kind ||= GobiertoBudgets::BudgetLine::EXPENSE if action_name == 'ranking'
      @area_name = params[:area] || 'functional'
      @year = params[:year].present? ? params[:year].to_i : nil
      @code = params[:code]
      @places_collection = params[:places_collection]&.to_sym || :ine
      @selected_place = GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find(params[:ine_code], places_collection: @places_collection) if params[:ine_code]

      if params[:variable].present?
        @variable = params[:variable]
        render_404 and return unless valid_variables.include?(@variable)
      end
    end

    def solve_income_area_mismatch
      area = (params[:area].present? ? params[:area].downcase : '')
      kind = (params[:kind].present? ? params[:kind].downcase : '')
      if %w{income i}.include?(kind) && area == 'functional'
        redirect_to url_for params.merge(area: 'economic', kind: 'I') and return
      end
    end

    def get_places(slug_list)
      slug_list.split(':').map { |slug| GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find_by_slug(slug, places_collection: @places_collection) }.compact
    end

    def valid_variables
      ['amount','amount_per_inhabitant','population']
    end

    def set_current_organization
      @current_organization = if params[:slug]
                                Organization.new(slug: params[:slug], places_collection: params[:places_collection])
                              elsif params[:organization_id]
                                Organization.new(id: params[:organization_id], places_collection: params[:places_collection])
                              end
      render_404 and return if @current_organization.nil? || (@current_organization.place.nil? && @current_organization.associated_entity.nil?)
    end

  end
end
