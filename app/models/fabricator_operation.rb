class FabricatorOperation < ApplicationRecord
  belongs_to :fabricator

  validates :operation_code, presence: true, inclusion: { in: JobProcess::PROCESS_OPTIONS.keys }
  validates :operation_code, uniqueness: { scope: :fabricator_id }
end
