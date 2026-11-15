# Loads the budget documents in spec/fixtures/elasticsearch into the test indices.
# They hold Madrid (28079) and Santander (39075) budgets for 2024 and 2025.
module ElasticsearchFixtures
  FIXTURES_PATH = Rails.root.join("spec/fixtures/elasticsearch")

  def self.load
    client = GobiertoBudgets::SearchEngine.client

    Dir[FIXTURES_PATH.join("*.json")].each do |path|
      index = GobiertoBudgets::SearchEngineConfiguration::INDEX_PREFIX + File.basename(path, ".json")
      fixture = JSON.parse(File.read(path))

      client.indices.delete(index:) if client.indices.exists?(index:)
      client.indices.create(index:, body: { mappings: fixture["mappings"] })

      operations = fixture["documents"].map do |document|
        { index: { _index: index, _id: document["id"], data: document["source"] } }
      end
      client.bulk(body: operations, refresh: true) if operations.any?
    end
  end
end
