module GobiertoBudgets
  module ApplicationHelper
    def pending(&block)
      if controller_name == 'sandbox'
        yield
      end
    end

    def sign(v1, v2 = nil)
      return 'sign-neutral' if v1.blank? || v2.blank?
      diff = v1 - v2
      if diff > 0
        'sign-up'
      elsif diff < 0
        'sign-down'
      else
        'sign-neutral'
      end
    rescue
      'sign-neutral'
    end

    def format_currency(n, absolute_value = false)
      return nil if n.blank?
      n = n.to_f
      n = n.abs if absolute_value

      if n.abs > 1_000_000
        "#{helpers.number_with_precision(n.to_f / 1_000_000.to_f, precision: 0, strip_insignificant_zeros: true)}M€"
      else
        helpers.number_to_currency(n, precision: 0, strip_insignificant_zeros: true)
      end
    end

    def delta_percentage(current_year_value, old_value)
      number_with_precision(((current_year_value.to_f - old_value.to_f)/old_value.to_f) * 100, precision: 2).to_s + "%"
    end

    def percentage_of_total(value, total)
      number_with_precision((value.to_f / total.to_f) * 100, precision: 2) + '%'
    end

    def area_class(area, kind)
      return GobiertoBudgets::FunctionalArea if (area == 'functional' && %{income i}.exclude?(kind.downcase))
      GobiertoBudgets::EconomicArea
    end

    def budget_line_denomination(area, code, kind, capped = -1)
      area = area_class area, kind
      if area.all_items[kind][code].nil?
        res = " - "
      else
        res = area.all_items[kind][code][0..capped]
        res += "..." if capped < res.length && capped > -1
      end
      res
    end

    def budget_line_description(area_name, code, kind, current_organization_slug)
      area = area_class area_name, kind
      description = area.all_descriptions[I18n.locale][area_name][kind][code.to_s]
      name = area.all_items[kind][code]
      if description != name
        return description
      elsif description.present?
        kind_what = kind == 'I' ? t('common.incomes') : t('common.expenses')

        I18n.t(
          "helpers.budget_line_description",
          kind_what: kind_what,
          description: description.downcase,
          link: link_to(
            budget_line_denomination(area_name, code[0..-2], kind),
            location_budget_line_path(current_organization_slug, params[:year], code[0..-2], kind, area_name)
          )
        ).html_safe
      end
    end

    def location_budget_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputation_budget_path(*args)
      else
        gobierto_budgets_place_budget_path(*args)
      end
    end

    def location_execution_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputation_execution_path(*args)
      else
        gobierto_budgets_place_execution_path(*args)
      end
    end

    def location_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputation_path(*args)
      else
        gobierto_budgets_place_path(*args)
      end
    end

    def locations_global_ranking_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_ranking_path(*args)
      else
        gobierto_budgets_ranking_path(*args)
      end
    end

    def locations_ranking_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_places_ranking_path(*args)
      else
        gobierto_budgets_places_ranking_path(*args)
      end
    end

    def locations_ranking_url(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_places_ranking_url(*args)
      else
        gobierto_budgets_places_ranking_url(*args)
      end
    end

    def location_budget_line_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputation_budget_line_path(*args)
      else
        gobierto_budgets_budget_line_path(*args)
      end
    end

    def locations_population_ranking_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_population_ranking_path(*args)
      else
        gobierto_budgets_population_ranking_path(*args)
      end
    end

    def locations_compare_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_compare_path(*args)
      else
        gobierto_budgets_compare_path(*args)
      end
    end

    def locations_places_compare_path(*args)
      if params[:places_collection] == "deputation_eu"
        gobierto_budgets_deputations_places_compare_path(*args)
      else
        gobierto_budgets_places_compare_path(*args)
      end
    end

    def kind_literal(kind, plural = true)
      if I18n.locale == :eu
        "gastu"
      else
        t("#{kind_key(kind)}#{plural ? "s" : ""}", scope: "common")
      end
    end

    def kind_key(kind)
      kind == "I" ? "income" : "expense"
    end

    def area_literal(area)
      area == 'functional' ? 'Funcional' : 'Económica'
    end

    def other_kind(kind)
      kind == 'I' ? 'G' : 'I'
    end

    def budget_line_crumbs(budget_line, type)
      crumbs = [budget_line]
      parent_code = budget_line['parent_code']

      while parent_code.present? do
        p = GobiertoBudgets::BudgetLine.find(ine_code: budget_line['ine_code'], code: parent_code, year: budget_line['year'], kind: budget_line['kind'], type: type)
        break if p.nil?
        crumbs.unshift(p)
        parent_code = p['parent_code']
      end

      return crumbs
    end

    def link_to_parent_comparison(places, year, kind, area_name, parent_code)
      options = {}
      options[:parent_code] = parent_code[0..-2] if parent_code.length > 1
      link_to('« anterior', locations_places_compare_path(places.map(&:slug).join(':'),year,kind,area_name, options))
    end

    def lines_chart_api_path(what, compared_level, places, year, kind, parent_code = nil, area_name = 'economic')
      place_ids = places.map(&:id).join(':')

      path = if compared_level > 1
        gobierto_budgets_api_data_compare_budget_lines_path(
          place_ids,
          year, what,
          kind,
          parent_code,
          area_name,
          format: :json,
          places_collection: params[:places_collection]
        )
      else
        gobierto_budgets_api_data_compare_path(place_ids, year, what, kind: kind, format: :json, places_collection: params[:places_collection])
      end
      path
    end

    def items_in_level(budget_lines, level, parent_code)
      budget_lines.select {|bl| bl['level'] == level && bl['parent_code'] == parent_code }.uniq{|bl| bl['code'] }
    end

    def categories_in_level(area, kind, level, parent_code)
      area = area_class area, kind
      area.all_items[kind].select{|k,v| k.length == level && k.starts_with?(parent_code.to_s)}.sort_by{|k,v| k}
    end

    def filter_location_name
      name = ""
      if @filter.location?
        name = @filter.location.name
        if @filter.location.is_a?(INE::Places::Province)
          name += " (Provincia)"
        elsif @filter.location.is_a?(INE::Places::AutonomousRegion)
          name += " (CCAA)"
        end
      end

      name
    end

    def data_attributes
      attrs = []

      target = @place || try(:current_organization)
      if target
        # TODO: Hacer dinamico
        attrs << %Q{data-bubbles-data="https://gobierto-populate-#{Rails.env.development? ? 'dev' : Rails.env }.s3.eu-west-1.amazonaws.com/gobierto_budgets/#{current_organization.id}/data/bubbles.json"}
        attrs << %Q{data-max-year="#{GobiertoBudgets::SearchEngineConfiguration::Year.last}"}
        # TODO: End TODO
        attrs << %Q{data-track-url="#{location_path(target.slug, @year || GobiertoBudgets::SearchEngineConfiguration::Year.last)}"}
        attrs << %Q{data-place-slug="#{target.slug}"}
        attrs << %Q{data-place-name="#{target.name}"}
      end
      if action_name == 'compare' and controller_name == 'places'
        attrs << %Q{data-comparison-name="#{@places.map{|p| p.name }.join(' + ')}"}
        attrs << %Q{data-comparison-track-url="#{request.path}"}
        attrs << %Q{data-comparison-slug="#{params[:slug_list]}"}
      end
      attrs << %Q{data-year="#{@year || GobiertoBudgets::SearchEngineConfiguration::Year.last}"}
      attrs << %Q{data-kind="#{@kind || 'expense'}"}
      attrs << %Q{data-area="#{@area_name || 'economic'}"}
      attrs << %Q{data-action="#{action_name}"}
      attrs << %Q{data-no-turbolink="true"} if action_name == 'map'
      attrs.join(' ').html_safe
    end

    def ranking_variable(what)
      if what == 'amount_per_inhabitant'
        @code.present? ? what : 'total_budget_per_inhabitant'
      elsif what == 'amount'
        @code.present? ? what : 'total_budget'
      elsif what == 'population'
        'value'
      end
    end

    def compare_slug(place, year)
      "#{place.name}|#{location_path(place.slug, year)}|#{place.slug}"
    end

    def place_name(organization_id, places_collection: :ine)
      return if organization_id.blank?

      if places_collection.to_sym == :ine
        INE::Places::Place.find(organization_id).try(:name)
      else
        GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find(organization_id, places_collection:).try(:name)
      end
    end

    def places_for_select
      INE::Places::Place.all.map do |place|
        [place.name, place.id]
      end
    end

    def rankings_select
      array = []
      array.concat([[t('gobierto_budgets.pages.home.whole_spain'),'']]) if !GobiertoBudgets::SearchEngineConfiguration::Scopes.places_scope?
      array.concat(INE::Places::AutonomousRegion.all.sort_by(&:name).map do |ar|
        [ar.name, ar.id]
      end)
    end

    def parent_code(code)
      if code.present?
        if code.include?('-')
          code.split('-').first
        else
          code[0..-2]
        end
      end
    end

    def twitter_share(message, url)
      short_url_length = 24
      total_message_length = 140
      signature = "#{I18n.t('helpers.in')} #{Settings.twitter_account}: "
      max_message_length = total_message_length - short_url_length - signature.length

      to_share = signature
      to_share += (message.length > max_message_length) ? message.slice(0, max_message_length - 3) + "..." : message
      to_share += " "+url
      to_share
    end

    def gobierto_budgets_answers_path_with_params(question_id, answer_text)
      gobierto_budgets_answers_path(answer: {
        question_id: question_id, answer_text: answer_text,
        place_id: current_organization.place_id, year: @year, kind: @kind, area_name: @area_name, code: @code
      })
    end

    def markdown(text)
      return if text.blank?

      options = {
        filter_html:     true,
        hard_wrap:       true,
        link_attributes: { rel: 'nofollow', target: "_blank" },
        space_after_headers: true,
        fenced_code_blocks: true
      }

      extensions = {
        autolink:           true,
        superscript:        true,
        disable_indented_code_blocks: true
      }

      renderer = Redcarpet::Render::HTML.new(options)
      markdown = Redcarpet::Markdown.new(renderer, extensions)

      markdown.render(text).html_safe
    end

  end
end
