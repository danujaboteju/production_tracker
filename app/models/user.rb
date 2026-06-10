class User < ApplicationRecord
  ROLES = %w[admin manager operator viewer].freeze

  has_secure_password

  has_many :sessions, dependent: :destroy

  before_validation :normalize_username

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  def admin?
    role == "admin"
  end

  private

  def normalize_username
    self.username = username.to_s.strip.downcase if username.present?
    self.role = "operator" if role.blank?
  end
end
