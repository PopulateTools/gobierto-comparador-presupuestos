require "rails_helper"

RSpec.describe "Password resets" do
  let!(:user) { create_user(email: "foo@example.com", password: "foo123456") }

  it "sends the reset instructions" do
    expect {
      post "/password_resets", params: { email: "foo@example.com" }
    }.to change(ActionMailer::Base.deliveries, :size).by(1)

    expect(response).to redirect_to("/municipios")
    expect(ActionMailer::Base.deliveries.last.to).to eq(["foo@example.com"])
    expect(user.reload.password_reset_token).to be_present
  end

  it "rejects an unknown email" do
    post "/password_resets", params: { email: "unknown@example.com" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("E-mail no es válido")
  end

  it "changes the password with a valid token" do
    post "/password_resets", params: { email: "foo@example.com" }
    token = user.reload.password_reset_token

    get "/password_resets/#{token}/edit"
    expect(response).to have_http_status(:ok)

    patch "/password_resets/#{token}", params: { user: { password: "changed123", password_confirmation: "changed123" } }

    expect(response).to redirect_to("/user/edit")
    expect(user.reload.authenticate("changed123")).to eq(user)
    expect(user.password_reset_token).to be_nil
  end

  it "shows an error for an invalid token" do
    get "/password_resets/wadus/edit"

    expect(response.body).to include("Parece que el enlace que has pinchado es inválido")
  end
end
