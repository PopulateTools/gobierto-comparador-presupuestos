class User < ActiveRecord::Base
  include UserSession

  has_secure_password validations: false, reset_token: false

  attr_accessor :remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, length: { maximum: 255 }, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :first_name, length: { maximum: 50 }
  validates :last_name, length: { maximum: 50 }
  validates :password, length: { minimum: 5 }, presence: true, confirmation: true, on: :update, if: Proc.new{|u| u.pending_confirmation? }
  validates :terms_of_service, acceptance: { accept: true }, on: :update
  validates :place_id, presence: true, on: :update

  before_validation :sanitize_parameters
  before_create :set_verification_token
  after_create :send_verification_email
  after_save :to_mailchimp

  scope :sorted, -> { order(id: :desc) }
  scope :admin, -> { where(admin: true) }
  scope :regular, -> { where(admin: false) }

  has_many :subscriptions, dependent: :destroy, class_name: "GobiertoBudgets::Subscription"

  def full_name
    @full_name ||= [first_name, last_name].compact.join(' ')
  end

  def pending_confirmation?
    self.verification_token.present?
  end

  def clear_verification_token
    self.verification_token = nil
  end

  def update_pending_answers(session_id)
    GobiertoBudgets::Answer.where(temporary_user_id: session_id.to_s).update_all(user_id: self.id, temporary_user_id: nil)
  end

  def has_replied?(options)
    GobiertoBudgets::Answer.where(options.merge(user_id: self.id)).first
  end

  def answered_consultation?(consultation)
    answers.where(consultation_id: consultation.id).exists?
  end

  def get_subscriptions_on(place)
    if place
      subscriptions.find_by(place_id: place.id)
    end
  end

  def location_by_collection(collection_key)
    return if place_id.blank?

    GobiertoBudgetsData::GobiertoBudgets::PlaceDecorator.collection(collection_key).find do |location|
      location.population_place_ids.include? place_id.to_s
    end
  end

  def in_mailchimp?
    Mailchimp.is_member?(self)
  end

  private

  def set_verification_token
    self.verification_token = generate_token
  end

  def sanitize_parameters
    self.email = self.email.downcase.strip if self.email.present?
    self.first_name = self.first_name.strip if self.first_name.present?
    self.last_name = self.last_name.strip if self.last_name.present?
  end

  def send_verification_email
    UserMailer.verification_notification(self).deliver_now
  end

  def to_mailchimp
    ::UpdateOrCreateInMailchimpJob.perform_later(self) if Rails.env.production?
  end

end
