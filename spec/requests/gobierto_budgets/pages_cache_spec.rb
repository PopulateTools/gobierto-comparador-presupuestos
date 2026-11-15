require "rails_helper"

RSpec.describe "Pages cache" do
  around do |example|
    cache_store = ActionController::Base.cache_store
    ActionController::Base.perform_caching = true
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    ActionController::Base.perform_caching = false
    ActionController::Base.cache_store = cache_store
  end

  it "caches the municipalities and deputations home pages separately" do
    get "/diputaciones"
    get "/municipios"

    expect(response.body).to include('placeholder="Busca municipio..."')
  end

  it "caches the municipalities and deputations ranking pages separately" do
    get "/ranking/diputaciones"
    get "/ranking/municipios"

    expect(response.body).to include("/api/data/widget/ranking/ine/")
  end
end
