require 'rails_helper'

describe GobiertoBudgets::BudgetLine do
  let(:client) { GobiertoBudgets::SearchEngine.client }
  let(:index) { GobiertoBudgets::SearchEngineConfiguration::BudgetLine.index_forecast }
  let(:organization_id) { "budget-line-spec" }
  let(:documents) do
    [
      { code: "1", level: 1 },
      { code: "2", level: 1 },
      { code: "11", level: 2, parent_code: "1" },
      { code: "111", level: 3, parent_code: "11" }
    ].map do |attributes|
      { organization_id:, year: 2001, kind: "G", type: "economic", amount: 1.0 }.merge(attributes)
    end
  end

  before do
    documents.each do |document|
      client.index(index:, id: document_id(document), body: document, refresh: true)
    end
  end

  after do
    documents.each do |document|
      client.delete(index:, id: document_id(document), refresh: true)
    end
  end

  def document_id(document)
    [organization_id, document[:year], document[:code], document[:kind], document[:type]].join("/")
  end

  describe ".codes_with_children" do
    it "returns the codes of the budget lines that have children" do
      budget_lines = described_class.search(organization_id:, year: 2001, kind: "G", type: "economic", level: 1)["hits"]

      expect(described_class.codes_with_children(budget_lines, "economic")).to eq(Set["1"])
    end

    it "returns no codes when there are no budget lines" do
      expect(described_class.codes_with_children([], "economic")).to be_empty
    end
  end
end
