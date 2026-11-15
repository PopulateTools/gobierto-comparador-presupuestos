require 'rails_helper'

describe "Rankings" do
  before do
    host! 'presupuestos.' + Settings.gobierto_host
  end

  it "renders the municipalities population ranking" do
    get '/ranking/municipios/2015/population'

    expect(response).to have_http_status(:ok)
  end

  context "with a place that has population but no budget for the year" do
    let(:population_document_id) { "rankings-spec-28079-2001" }

    before do
      GobiertoBudgets::SearchEngine.client.index(
        index: GobiertoBudgets::SearchEngineConfiguration::Data.index,
        id: population_document_id,
        refresh: true,
        body: { organization_id: "28079", ine_code: 28079, type: "population", province_id: "28", autonomy_id: "13", year: 2001, value: 3_000_000 }
      )
    end

    after do
      GobiertoBudgets::SearchEngine.client.delete(
        index: GobiertoBudgets::SearchEngineConfiguration::Data.index,
        id: population_document_id,
        refresh: true
      )
    end

    it "renders the place without budget amounts" do
      get '/ranking/municipios/2001/population'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Madrid")
    end
  end

  it "renders the deputations population ranking" do
    get '/ranking/diputaciones/2015/population'

    expect(response).to have_http_status(:ok)
  end

  it "renders the deputations rankings page" do
    get '/ranking/diputaciones'

    expect(response).to have_http_status(:ok)
  end

  it "redirects rankings paths without a places collection to the municipalities rankings" do
    get '/ranking/2015/population'

    expect(response).to redirect_to('/ranking/municipios/2015/population')
  end
end
