require "rails_helper"

RSpec.describe "Categories search" do
  def json
    JSON.parse(response.body)
  end

  it "suggests the budget lines with data of a municipality" do
    get "/categories/madrid/2025/functional/G.json", params: { query: "servicios" }

    expect(json["suggestions"]).to eq([
      { "value" => "Servicios públicos básicos", "data" => { "url" => "/municipios/madrid/partida/2025/1/G/functional" } }
    ])
  end

  it "lists all the categories" do
    get "/api/categories.json"

    expect(json.keys).to eq(%w(economic functional))
    expect(json["economic"].keys).to eq(%w(I G))
    expect(json["functional"].keys).to eq(%w(G))
  end

  it "lists the categories of an area and kind" do
    get "/api/categories/functional/G.json"

    expect(json["1"]).to eq("Servicios públicos básicos")
  end

  it "returns not found for functional income categories" do
    get "/api/categories/functional/I.json"

    expect(response).to have_http_status(:not_found)
  end
end
