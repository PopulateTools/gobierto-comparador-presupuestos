require 'rails_helper'

describe GobiertoBudgets::ApplicationHelper, type: :helper do
  describe "#compare_slug" do
    it "links an organization to its place page" do
      organization = GobiertoBudgets::Organization.new(slug: "huesca")

      expect(helper.compare_slug(organization, 2021)).to eq("Huesca|/municipios/huesca/2021|huesca")
    end

    it "links a ranking place to its place page" do
      place = GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.find("22125", places_collection: :ine)

      expect(helper.compare_slug(place, 2021)).to eq("Huesca|/municipios/huesca/2021|huesca")
    end
  end
end
