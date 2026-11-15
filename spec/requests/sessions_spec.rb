require "rails_helper"

RSpec.describe "Sessions" do
  let!(:user) { create_user(email: "foo@example.com", password: "foo123456") }

  it "renders the login form" do
    get "/login"

    expect(response).to have_http_status(:ok)
  end

  it "logs in with valid credentials" do
    post "/sessions", params: { session: { email: "FOO@example.com", password: "foo123456" }, back_url: "/about" }

    expect(response).to redirect_to("/about")
    expect(session[:user_id]).to eq(user.id)
  end

  it "rejects invalid credentials" do
    post "/sessions", params: { session: { email: "foo@example.com", password: "wrong" } }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Credenciales incorrectas")
    expect(session[:user_id]).to be_nil
  end

  it "logs out" do
    post "/sessions", params: { session: { email: "foo@example.com", password: "foo123456" }, back_url: "/about" }
    delete "/logout"

    expect(response).to redirect_to("/municipios")
    expect(session[:user_id]).to be_nil
  end
end
