require "rails_helper"

RSpec.describe "Pages" do
  it "redirects the root to the municipalities home page" do
    get "/"

    expect(response).to redirect_to("/municipios")
  end

  it "renders the municipalities home page" do
    get "/municipios"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Santander")
  end

  it "renders the deputations home page" do
    get "/diputaciones"

    expect(response).to have_http_status(:ok)
  end

  %w(/about /faq /pro /legal/cookies /legal/legal /legal/privacy /request_access).each do |path|
    it "renders #{path}" do
      get path

      expect(response).to have_http_status(:ok)
    end
  end

  it "renders the municipalities ranking page" do
    get "/ranking/municipios"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/api/data/widget/ranking/ine/2025/I/economic/amount/344.json")
  end

  it "renders the deputations ranking page" do
    get "/ranking/diputaciones"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/api/data/widget/ranking/deputation_eu/2025/I/economic/amount/391.json")
  end

  it "redirects the ranking paths without places collection to the municipalities ranking" do
    get "/ranking/2024/G/economic/amount"

    expect(response).to redirect_to("/ranking/municipios/2024/G/economic/amount")
  end

  it "renders the compare pages" do
    get "/compara/municipios"
    expect(response).to have_http_status(:ok)

    get "/compara/diputaciones"
    expect(response).to have_http_status(:ok)
  end

  it "renders the map for a valid year" do
    get "/mapas/2024"

    expect(response).to have_http_status(:ok)
  end

  it "redirects the map to the last year when the year is out of range" do
    get "/mapas/1999"

    expect(response).to redirect_to("/mapas/2025")
  end

  it "sets the locale" do
    get "/locale/en", headers: { "HTTP_REFERER" => "/about" }

    expect(response).to redirect_to("/about")
    expect(session[:locale]).to eq(:en)
  end
end
