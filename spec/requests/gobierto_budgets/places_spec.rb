require "rails_helper"

RSpec.describe "Places" do
  describe "show" do
    it "redirects to the last year when no year is given" do
      get "/municipios/madrid"

      expect(response).to redirect_to("/municipios/madrid/2025")
    end

    it "renders the budget summary of a municipality" do
      get "/municipios/madrid/2024"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid")
    end

    it "renders a year without data" do
      get "/municipios/santander/2015"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Santander")
    end

    it "returns not found for an unknown municipality" do
      get "/municipios/unknown-place/2024"

      expect(response).to have_http_status(:not_found)
    end

    it "redirects a deputation without data to its previous year" do
      get "/diputaciones/dip-bizkaia/2024"

      expect(response).to have_http_status(:found)
      expect(response.location).to match(%r{/diputaciones/dip-bizkaia/\d{4}\z})
    end
  end

  describe "budget" do
    it "returns the treemap of the first level" do
      get "/municipios/madrid/2024/G/functional.json"

      expect(response).to have_http_status(:ok)
      codes = JSON.parse(response.body)["children"].map { |line| line["code"] }
      expect(codes).to include("1", "2", "3")
    end

    it "returns the treemap of a parent budget line" do
      get "/municipios/madrid/2024/G/functional/parent/1.json"

      expect(response).to have_http_status(:ok)
      codes = JSON.parse(response.body)["children"].map { |line| line["code"] }
      expect(codes).to eq(["13"])
    end

    it "redirects functional income to economic income" do
      get "/municipios/madrid/2024/I/functional.json"

      expect(response).to redirect_to("/municipios/madrid/2024/I/economic.json")
    end
  end

  it "renders the execution page" do
    get "/municipios/madrid/2024/execution"

    expect(response).to have_http_status(:ok)
  end

  it "renders the debt page" do
    get "/municipios/madrid/2024/debt"

    expect(response).to have_http_status(:ok)
  end

  describe "compare" do
    it "compares the first level of several municipalities" do
      get "/compara/municipios/madrid:santander/2024/G/functional"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid", "Santander")
    end

    it "compares a budget line of several municipalities" do
      get "/compara/municipios/madrid:santander/2024/G/functional", params: { parent_code: "1" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "ranking" do
    it "ranks municipalities by total budget" do
      get "/ranking/municipios/2024/G/functional/amount"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid", "Santander")
    end

    it "ranks municipalities by a budget line per inhabitant" do
      get "/ranking/municipios/2024/G/functional/amount_per_inhabitant/1"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid", "Santander")
    end

    it "ranks municipalities by population" do
      get "/ranking/municipios/2024/population"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid", "Santander", 'data-ranking-url="/ranking/municipios/2024/population"')
    end

    it "filters the ranking by population" do
      get "/ranking/municipios/2024/G/functional/amount", params: { f: { population: { from: 800_000, to: 1_000_000 } } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid")
      expect(response.body).not_to include("Santander")
    end

    it "returns not found for an unknown variable" do
      get "/ranking/municipios/2024/G/functional/wadus"

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for a page out of bounds" do
      get "/ranking/municipios/2024/G/functional/amount/p/50"

      expect(response).to have_http_status(:not_found)
    end
  end

  it "redirects an INE code to the municipality page" do
    get "/municipios/39075/2024/redirect"

    expect(response).to redirect_to("/municipios/santander/2024")
  end
end
