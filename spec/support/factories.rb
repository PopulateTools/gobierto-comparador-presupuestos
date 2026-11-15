module Factories
  def create_user(attrs = {})
    attrs[:email]     ||= "foo@example.com"
    attrs[:password]  ||= "foo123456"
    attrs[:password_confirmation] ||= attrs[:password]
    attrs[:place_id] ||= 28079
    attrs[:terms_of_service] ||= true
    User.new(attrs).tap do |u|
      u.save!
      u.clear_verification_token
      u.save!
    end
  end

  def create_commenter(attrs = {})
    create_user({email: 'comenter@example.com'}.merge(attrs))
  end


  def create_admin(attrs = {})
    create_user email: 'admin@example.com', password:'adminadmin', admin: true
  end
end
