module GobiertoBudgets
  class SearchEngineConfiguration
    class Year
      def self.last; 2025 end
      def self.first; 2010 end
      def self.all
        @all ||= (first..last).to_a.reverse
      end
    end
    class BudgetLine
      def self.index_forecast; 'budgets-forecast' end
      def self.index_executed; 'budgets-execution' end
      def self.index_forecast_updated; 'budgets-forecast-updated' end
    end

    class TotalBudget
      def self.index_forecast; 'budgets-forecast' end
      def self.index_executed; 'budgets-execution' end
      def self.index_forecast_updated; 'budgets-forecast-updated' end
      def self.type; 'total-budget' end

      def self.all_indices
        [index_forecast, index_executed, index_forecast_updated]
      end
    end

    class Data
      def self.index; 'data' end
      def self.type_population; 'population' end

      # Pending to add GobiertoBudgetsData::GobiertoBudgets::POPULATION_PROVINCE_TYPE
      # and GobiertoBudgetsData::GobiertoBudgets::POPULATION_AUTONOMY_TYPE
      # to gobierto_budgets_data
      def self.type_population_province; 'population-province' end
      def self.type_population_autonomy; 'population-autonomy' end

      def self.type_places; 'places-v2' end
      def self.type_debt; 'debt' end
    end

    class Scopes
      cattr_reader :organization_ids

      def self.set_places_scope(places)
        @organization_ids ||= places.map(&:id).compact_blank
        @places_ids ||= places.map { |i| i.id.to_i }
      end

      def self.places_scope?
        @places_ids.present? || @organization_ids.present?
      end

      def self.places_scope
        @places_ids
      end

      def self.organizations_scope
        @organization_ids
      end
    end
  end
end
