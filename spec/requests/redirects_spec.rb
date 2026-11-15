require "rails_helper"

RSpec.describe "Redirects" do
  {
    "/" => "/municipios",
    "/places/madrid/2024" => "/municipios/madrid/2024",
    "/budget_lines/madrid/2024/1/G/functional" => "/municipios/madrid/partida/2024/1/G/functional",
    "/compare" => "/compara/municipios",
    "/compare/madrid:santander/2024/G/economic" => "/compara/municipios/madrid:santander/2024/G/economic",
    "/compare-new" => "/compara/municipios/nueva",
    "/ranking" => "/ranking/municipios",
    "/ranking/2024/G/economic/amount" => "/ranking/municipios/2024/G/economic/amount"
  }.each do |from, to|
    it "redirects #{from} to #{to}" do
      get from

      expect(response).to have_http_status(:moved_permanently)
      expect(response.headers["location"]).to eq(to)
    end
  end
end
