require "rails_helper"

RSpec.describe "Data API" do
  def json
    JSON.parse(response.body)
  end

  describe "municipality widgets" do
    it "returns the total budget" do
      get "/api/data/widget/total_budget/madrid/2025.json"

      expect(json).to include(
        "value" => "578.006 €",
        "delta_percentage" => "61,77",
        "ranking_position" => 1,
        "ranking_total_elements" => "2",
        "ranking_url" => "/ranking/municipios/2025/G/economic/amount/p/1?ine_code=28079"
      )
    end

    it "returns the total budget per inhabitant" do
      get "/api/data/widget/total_budget_per_inhabitant/madrid/2025.json"

      expect(json).to include("value" => "516.829 €", "ranking_position" => 2)
    end

    it "returns the total budget execution" do
      get "/api/data/widget/total_widget_execution/madrid/2024.json"

      expect(json).to include("sign" => "sign-up", "delta_percentage" => "157,61", "value" => 563_140)
    end

    it "returns the population" do
      get "/api/data/widget/population/28079/2025.json"

      expect(json).to include(
        "value" => "705.377",
        "delta_percentage" => "-24,30",
        "ranking_url" => "/ranking/municipios/2025/population/1?ine_code=28079",
        "no_data_this_year" => nil
      )
    end

    it "falls back to the previous year population" do
      get "/api/data/widget/population/28079/2026.json"

      expect(json).to include("value" => "705.377")
    end

    it "returns the debt" do
      get "/api/data/widget/debt/madrid/2025.json"

      expect(json).to include("value" => "28.555 €", "ranking_position" => 1)
    end

    it "returns a budget line amount" do
      get "/api/data/widget/budget/madrid/2025/1/functional/G.json"

      expect(json).to include(
        "value" => "461.539 €",
        "delta_percentage" => "117,34",
        "ranking_url" => "/ranking/municipios/2025/G/functional/amount/1/p/1?ine_code=28079"
      )
    end

    it "returns a budget line execution" do
      get "/api/data/widget/budget_execution/madrid/2024/1/functional/G.json"

      expect(json).to include("value" => "271.985 €", "delta_percentage" => "28,08")
    end

    it "returns a budget line amount per inhabitant" do
      get "/api/data/widget/budget_per_inhabitant/madrid/2025/1/functional/G.json"

      expect(json).to include("value" => "273 €", "ranking_position" => 1)
    end

    it "returns a budget line percentage over the total budget" do
      get "/api/data/widget/budget_percentage_over_total/madrid/2025/1/functional/G.json"

      expect(json).to include("value" => "79,85%")
    end

    it "returns a budget line percentage over the previous year" do
      get "/api/data/widget/budget_percentage_previous_year/madrid/2025/1/functional/G.json"

      expect(json).to include("value" => "117,34%")
    end

    it "returns the expense execution deviation with its evolution" do
      get "/api/data/widget/budget_execution_deviation/madrid/2024/G.json"

      expect(json).to include(
        "deviation_heading" => "Desviación de los gastos en 2024",
        "deviation_percentage" => "157,61"
      )
      expect(json["G"]).to include("total_budgeted" => "357.309 €", "total_executed" => "920.449 €")
      expect(json["G"]["evolution"].map { |item| item["year"] }).to eq([2024, 2025])
    end

    it "returns the income execution deviation" do
      get "/api/data/widget/budget_execution_deviation/madrid/2024/I.json"

      expect(json).to include("deviation_percentage" => "-28,19")
      expect(json["I"]).to include("total_budgeted" => "670.623 €", "total_executed" => "481.570 €")
    end
  end

  describe "ranking widgets" do
    it "returns the total ranking" do
      get "/api/data/widget/ranking/ine/2025/G/economic/amount.json"

      expect(json).to include(
        "title" => "Top gastos totales en 2025",
        "top_place_name" => "Madrid",
        "top_amount" => "578.006 €",
        "ranking_path" => "/ranking/municipios/2025/G/economic/amount",
        "top_5" => [{ "place_name" => "Madrid" }, { "place_name" => "Santander" }]
      )
    end

    it "returns the per inhabitant ranking" do
      get "/api/data/widget/ranking/ine/2025/G/functional/amount_per_inhabitant.json"

      expect(json).to include("top_place_name" => "Santander", "top_amount" => "928.520 €")
    end

    it "returns a budget line ranking" do
      get "/api/data/widget/ranking/ine/2025/G/functional/amount/1.json"

      expect(json).to include(
        "title" => "Top gastos totales en Servicios públicos básicos en 2025",
        "top_place_name" => "Santander"
      )
    end

    it "returns an income budget line ranking" do
      get "/api/data/widget/ranking/ine/2025/I/economic/amount/2.json"

      expect(json).to include("title" => "Top ingresos totales en Impuestos indirectos en 2025", "top_place_name" => "Madrid")
    end
  end

  describe "lines" do
    it "returns the evolution of a municipality compared with the means" do
      get "/api/data/lines/madrid/2025/total_budget.json"

      names = json["budgets"]["total_budget"].map { |line| line["name"] }
      expect(names).to eq(%w(Madrid mean_province mean_autonomy mean_national))
    end

    it "returns the evolution per inhabitant" do
      get "/api/data/lines/madrid/2025/total_budget_per_inhabitant.json"

      expect(json["budgets"]["total_budget_per_inhabitant"].first["name"]).to eq("Madrid")
    end

    it "returns the evolution of a budget line" do
      get "/api/data/lines/budget_line/madrid/2025/total_budget/G/1/functional.json"

      madrid = json["budgets"]["total_budget"].first
      expect(json["title"]).to eq("Servicios públicos básicos")
      expect(madrid["values"]).to eq([
        { "date" => "2025", "value" => 461_539, "dif" => 117.34 },
        { "date" => "2024", "value" => 212_358, "dif" => 0 }
      ])
    end

    it "compares the evolution of several municipalities" do
      get "/api/data/compare/28079:39075/2025/total_budget.json"

      names = json["budgets"]["total_budget"].map { |line| line["name"] }
      expect(names).to eq(%w(Madrid Santander))
    end

    it "compares the evolution of a budget line in several municipalities" do
      get "/api/data/compare/budget_line/28079:39075/2025/total_budget/G/1/functional.json"

      values = json["budgets"]["total_budget"].map { |line| line["values"].first["value"] }
      expect(values).to eq([461_539, 485_272])
    end
  end

  it "returns the budget lines of a municipality" do
    get "/api/data/madrid/2025/G/functional.json"

    expect(response).to have_http_status(:ok)
    expect(json.map { |line| line["organization_id"] }.uniq).to eq(["28079"])
    expect(json.first).to include("code" => "0", "category" => "Deuda pública")
  end

  it "returns the debt of the municipalities in euros" do
    get "/api/data/debt/2025.json"

    expect(json.map { |item| [item["organization_id"], item["value"]] }).to eq([["28079", 28_555_000], ["39075", 755_027_000]])
  end

  it "returns the population of the municipalities" do
    get "/api/data/population/2025.json"

    expect(json.map { |item| [item["organization_id"], item["value"]] }).to eq([["28079", 705_377], ["39075", 296_653]])
  end
end
