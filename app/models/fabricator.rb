class Fabricator < ApplicationRecord
  has_many :fabrication_logs, dependent: :restrict_with_error
  has_many :fabricator_operations, dependent: :destroy

  before_validation :trim_name

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true).order(:name) }
  scope :ordered, -> { order(Arel.sql("LOWER(name) ASC")) }
  scope :assigned_to_operation, ->(operation_code) {
    joins(:fabricator_operations)
      .where(fabricator_operations: { operation_code: operation_code })
      .distinct
  }

  def assigned_operation_codes
    fabricator_operations.order(:operation_code).pluck(:operation_code)
  end

  def assigned_to_operation?(operation_code)
    fabricator_operations.exists?(operation_code: operation_code)
  end

  private

  def trim_name
    self.name = name.to_s.strip
  end
end
