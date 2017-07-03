module GobiertoBudgets
  class SearchEngineConfiguration
    class Year
      def self.last; 2016 end
      def self.first; 2010 end
      def self.all
        @all ||= (first..last).to_a.reverse
      end
      def self.fallback_year?(year)
        year == self.last
      end
    end

    class BudgetCategories
      def self.index; 'tbi-collections' end
      def self.type
        if I18n.locale == :ca
          'c-categorias-presupuestos-municipales-cat'
        else
          'c-categorias-presupuestos-municipales'
        end
      end
    end

    class BudgetLine
      def self.index_forecast; 'budgets-forecast-v3' end
      def self.index_executed; 'budgets-execution-v3' end
      # TODO: add the types economic and functional
    end

    class TotalBudget
      def self.index_forecast; 'budgets-forecast-v3' end
      def self.index_executed; 'budgets-execution-v3' end
      def self.type; 'total-budget' end
    end

    class Data
      def self.index; 'data' end
      def self.type_population; 'population' end
      def self.type_places; 'places-v2' end
      def self.type_debt; 'debt' end
    end

    class Scopes
      def self.set_places_scope(places)
        @places_ids ||= places.map{|i| i.id.to_i }
      end

      def self.places_scope?
        @places_ids.present?
      end

      def self.places_scope
        @places_ids
      end
    end
  end
end
