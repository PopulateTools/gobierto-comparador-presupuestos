require "rails_helper"

RSpec.describe "Budget lines" do
  it "renders a functional expense budget line" do
    get "/municipios/madrid/partida/2024/1/G/functional"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Madrid")
  end

  it "renders an economic income budget line" do
    get "/municipios/santander/partida/2024/2/I/economic"

    expect(response).to have_http_status(:ok)
  end

  it "returns not found for a budget line without data" do
    get "/municipios/madrid/partida/2024/9/G/functional"

    expect(response).to have_http_status(:not_found)
  end

  it "renders the feedback question of a budget line" do
    get "/municipios/madrid/partida/2024/1/G/functional/feedback/1"

    expect(response).to have_http_status(:ok)
  end

  it "redirects the feedback path without places collection" do
    get "/budget_lines/madrid/2024/1/G/functional/feedback/1"

    expect(response).to redirect_to("/municipios/madrid/partida/2024/1/G/functional/feedback/1")
  end

  it "returns not found for an unknown feedback question" do
    get "/municipios/madrid/partida/2024/1/G/functional/feedback/3"

    expect(response).to have_http_status(:not_found)
  end
end
