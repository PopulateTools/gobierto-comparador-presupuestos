require "rails_helper"

RSpec.describe "Participation" do
  let(:answer_params) do
    { question_id: 2, answer_text: "Poco", place_id: 28079, kind: "G", area_name: "functional", year: 2025, code: "1" }
  end

  it "stores an anonymous answer about a budget line" do
    expect {
      post "/answers", params: { answer: answer_params }, xhr: true, as: :js
    }.to change(GobiertoBudgets::Answer, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(GobiertoBudgets::Answer.last).to have_attributes(user_id: nil, answer_text: "Poco")
  end

  it "follows a place" do
    user = create_user(email: "foo@example.com", password: "foo123456")
    post "/sessions", params: { session: { email: "foo@example.com", password: "foo123456" }, back_url: "/about" }

    post "/subscriptions", params: { place_id: 39075 }, xhr: true, as: :js

    expect(response).to have_http_status(:ok)
    expect(user.subscriptions.pluck(:place_id)).to eq([39075])

    delete "/subscriptions/#{user.subscriptions.first.id}", xhr: true, as: :js

    expect(user.subscriptions.reload).to be_empty
  end
end
