class Fabricator < ApplicationRecord
  has_many :fabrication_logs, dependent: :restrict_with_error

  before_validation :trim_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true).order(:name) }
  scope :ordered, -> { order(Arel.sql("LOWER(name) ASC")) }

  private

  def trim_name
    self.name = name.to_s.strip
  end
end
