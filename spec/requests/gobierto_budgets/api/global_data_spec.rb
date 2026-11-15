require "rails_helper"

RSpec.describe "Global data API" do
  def json
    JSON.parse(response.body)
  end

  it "returns the total budget of all municipalities" do
    get "/api/data/widget/global_total_budget/2025.json"

    expect(json).to include("value" => "615.181 €")
  end

  it "returns the total budget per inhabitant of all municipalities" do
    get "/api/data/widget/global_total_budget_per_inhabitant/2025.json"

    expect(json).to include("value" => "1 €", "delta_percentage" => "-29,21")
  end

  it "returns the population of all municipalities" do
    get "/api/data/widget/global_population/2025.json"

    expect(json).to include("value" => "1.002.030")
  end

  it "returns the debt of all municipalities" do
    get "/api/data/widget/global_debt/2025.json"

    expect(json).to include("value" => "783.582 €", "delta_percentage" => "23,11")
  end

  it "returns the execution of all municipalities" do
    get "/api/data/widget/global_total_budget_execution/2024.json"

    expect(json).to include("sign" => "sign-up", "delta_percentage" => "40,67", "value" => "462.259 €")
  end
end
