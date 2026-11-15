require "rails_helper"

RSpec.describe "Users" do
  def log_in(email, password)
    post "/sessions", params: { session: { email:, password: }, back_url: "/about" }
  end

  it "renders the sign up form" do
    get "/users/new"

    expect(response).to have_http_status(:ok)
  end

  it "signs up and sends the verification email" do
    expect {
      post "/users", params: { user: { email: "new@example.com", place_id: 28079, terms_of_service: "1" } }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to("/municipios")
    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["new@example.com"]])
  end

  it "does not sign up with an invalid email" do
    expect {
      post "/users", params: { user: { email: "wadus", place_id: 28079 } }
    }.not_to change(User, :count)

    expect(response).to have_http_status(:ok)
  end

  it "verifies a user and asks for the password" do
    post "/users", params: { user: { email: "new@example.com", place_id: 28079, terms_of_service: "1" } }
    user = User.find_by!(email: "new@example.com")

    get "/users/#{user.verification_token}/verify"

    expect(response).to have_http_status(:ok)
    expect(session[:user_id]).to eq(user.id)

    patch "/user", params: { user: { password: "secret123", password_confirmation: "secret123", place_id: 28079, terms_of_service: "1" } }

    expect(response).to redirect_to("/municipios")
    expect(user.reload.pending_confirmation?).to be(false)
    expect(user.authenticate("secret123")).to eq(user)
  end

  it "redirects the profile to the login when logged out" do
    get "/user/edit"

    expect(response).to redirect_to("/login")
  end

  it "updates the profile" do
    create_user(email: "foo@example.com", password: "foo123456")
    log_in("foo@example.com", "foo123456")

    get "/user/edit"
    expect(response).to have_http_status(:ok)

    patch "/user", params: { user: { first_name: "Foo", last_name: "Wadus" } }

    expect(response).to redirect_to("/municipios")
    expect(User.find_by!(email: "foo@example.com").full_name).to eq("Foo Wadus")
  end

  it "identifies an existing user" do
    create_user(email: "foo@example.com")

    expect {
      post "/users/identify", params: { user: { email: "foo@example.com" }, follow: "28079" }, headers: { "HTTP_REFERER" => "/municipios/madrid/2025" }
    }.not_to change(User, :count)

    expect(response).to redirect_to("/municipios/madrid/2025")
    expect(session[:follow]).to eq("28079")
  end
end
