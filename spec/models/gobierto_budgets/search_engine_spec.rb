require 'rails_helper'

describe GobiertoBudgets::SearchEngine do
  let(:index) { "search-engine-spec" }
  let(:client) { described_class.client }
  let(:query) { { bool: { must: [{ term: { year: 2001 } }] } } }

  before do
    client.indices.create(index:, body: { mappings: { properties: { year: { type: "integer" }, amount: { type: "float" } } } })
    { "a" => 30.0, "b" => 20.0, "c" => 20.0, "d" => 10.0 }.each do |id, amount|
      client.index(index:, id:, body: { year: 2001, amount: })
    end
    client.index(index:, id: "other-year", body: { year: 2002, amount: 50.0 })
    client.indices.refresh(index:)
  end

  after do
    client.indices.delete(index:)
  end

  describe ".ranking_position" do
    it "returns the position in descending order and the number of ranked documents" do
      expect(described_class.ranking_position(index:, query:, field: :amount, id: "d", value: 10.0)).to eq([4, 4])
    end

    it "gives tied documents the same position" do
      expect(described_class.ranking_position(index:, query:, field: :amount, id: "c", value: 20.0)).to eq([2, 4])
      expect(described_class.ranking_position(index:, query:, field: :amount, id: "b", value: 20.0)).to eq([2, 4])
    end

    it "returns no position for a document out of the ranking" do
      expect(described_class.ranking_position(index:, query:, field: :amount, id: "other-year", value: 50.0)).to eq([nil, 4])
    end
  end
end
