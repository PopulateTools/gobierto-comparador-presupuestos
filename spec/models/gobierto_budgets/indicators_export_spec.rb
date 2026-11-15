require "rails_helper"

describe GobiertoBudgets::IndicatorsExport do
  subject(:export) { described_class.new }

  def rows_of(csv, place_id)
    CSV.parse(csv, headers: true).select { |row| row["place_id"] == place_id }
  end

  describe "#write_indicators" do
    let(:csv) { StringIO.new.tap { |io| export.write_indicators(io) }.string }

    it "writes the header expected by the indicadores_presupuestos_municipales dataset" do
      expect(csv.lines.first.chomp).to eq("year,place_id,gasto_por_habitante,gasto_total,planned_vs_executed,population,debt")
    end

    it "writes the indicators of every municipality and year" do
      madrid = rows_of(csv, "28079").index_by { |row| row["year"] }

      expect(madrid.keys).to match_array(GobiertoBudgets::SearchEngineConfiguration::Year.all.map(&:to_s))
      expect(madrid["2025"].to_h).to eq(
        "year" => "2025", "place_id" => "28079", "gasto_por_habitante" => "516829.0", "gasto_total" => "578006.0",
        "planned_vs_executed" => "19.32", "population" => "705377", "debt" => "28555.0"
      )
      expect(madrid["2024"].to_h).to include("gasto_total" => "357309.0", "planned_vs_executed" => "157.61", "population" => "931804")
    end

    it "leaves the indicators empty when there is no data in the year or the previous ones" do
      expect(rows_of(csv, "28079").find { |row| row["year"] == "2023" }.to_h).to include(
        "gasto_por_habitante" => nil, "gasto_total" => nil, "planned_vs_executed" => nil, "population" => nil, "debt" => nil
      )
    end

    it "includes municipalities without data" do
      expect(rows_of(csv, "44001").size).to eq(GobiertoBudgets::SearchEngineConfiguration::Year.all.size)
    end

    context "when a municipality has no budget for a year" do
      let(:client) { GobiertoBudgets::SearchEngine.client }
      let(:index) { GobiertoBudgets::SearchEngineConfiguration::TotalBudget.index_forecast }
      let(:document_id) { "44001/2023/G/total-budget" }

      before do
        client.index(
          index:,
          id: document_id,
          refresh: true,
          body: { organization_id: "44001", year: 2023, kind: "G", type: "total-budget", amount: 1_000, amount_per_inhabitant: 10 }
        )
      end

      after do
        client.delete(index:, id: document_id, refresh: true)
      end

      it "uses the budget of the last previous year" do
        rows = rows_of(csv, "44001").index_by { |row| row["year"] }

        expect(rows["2025"].to_h).to include("gasto_por_habitante" => "10.0", "gasto_total" => "1000.0")
        expect(rows["2022"].to_h).to include("gasto_total" => nil)
      end
    end
  end

  describe "#write_planned_budgets" do
    let(:csv) { StringIO.new.tap { |io| export.write_planned_budgets(io) }.string }

    it "writes the header expected by the presupuestos_municipales dataset" do
      expect(csv.lines.first.chomp).to eq('"year","place_id","area","kind","amount","code","amount_per_inhabitant"')
    end

    it "writes the economic and functional budget lines of the municipalities" do
      madrid = rows_of(csv, "28079")

      expect(madrid.map { |row| row["area"] }.tally).to eq("e" => 30, "f" => 30)
      expect(madrid.map(&:to_h)).to include(
        "year" => "2024", "place_id" => "28079", "area" => "e", "kind" => "G", "amount" => "831846", "code" => "1", "amount_per_inhabitant" => "26.0"
      )
    end

    it "skips the economic lines broken down by functional code" do
      amounts = rows_of(csv, "28079").map { |row| row["amount"] }

      expect(amounts).not_to include("843616")
    end
  end
end
