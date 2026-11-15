require 'rails_helper'

describe "Search categories" do
  before do
    host! 'presupuestos.' + Settings.gobierto_host
  end

  it "responds with bad request when the query is missing" do
    get '/categories/madrid/2015/economic/I.json'

    expect(response).to have_http_status(:bad_request)
  end
end
