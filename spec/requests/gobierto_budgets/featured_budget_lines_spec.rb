require "rails_helper"

RSpec.describe "Featured budget lines" do
  it "renders the featured budget line of a municipality" do
    get "/featured_budget_lines/madrid", params: { year: 2025 }, xhr: true, as: :js

    expect(response).to have_http_status(:ok)
  end

  it "renders the embeddable featured budget line" do
    get "/featured_budget_lines/embed/28079"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("/municipios/madrid/partida/2025/1300/G/functional")
    expect(response.headers).not_to have_key("X-Frame-Options")
  end

  it "returns not found for an unknown municipality" do
    get "/featured_budget_lines/embed/99999"

    expect(response).to have_http_status(:not_found)
  end
end
