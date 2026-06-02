class JobProcess < ApplicationRecord
  belongs_to :job
  has_many :fabrication_logs, dependent: :destroy

  PROCESS_OPTIONS = {
    "PRODRAFT" => "Drafting",
    "PROCUT" => "Miter Saw Cutting",
    "PENTL" => "Tube Laser",
    "PROFL" => "Flat Bed Laser",
    "PROPB" => "Press Brake",
    "PRODRILL" => "Drilling / Punching",
    "PROFAB" => "Fabrication / Assembly",
    "PROGUIL" => "Guillotine",
    "PROPRIME" => "Priming",
    "PENRIME" => "Penrith Priming",
    "PRORO" => "Rolling",
    "PROPAINTYELLOW" => "Yellow Enamel Painting",
    "GAS" => "Galvanizing",
    "PRODEL" => "Delivery"
  }.freeze

  STAGE_MAP = {
    1 => ["PRODRAFT"],
    2 => ["PROCUT", "PENTL", "PROFL", "PROGUIL"],
    3 => ["PROPB", "PRORO"],
    4 => ["PROFAB", "PRODRILL"],
    5 => ["PROPRIME", "PENRIME", "PROPAINTYELLOW", "GAS"],
    6 => ["PRODEL"]
  }.freeze

  PROCESS_STAGES = STAGE_MAP.each_with_object({}) do |(stage_no, process_codes), stages|
    process_codes.each { |process_code| stages[process_code] = stage_no }
  end.freeze

  STAGE_NAMES = {
    1 => "Drafting",
    2 => "Cutting",
    3 => "Forming",
    4 => "Fabrication / Drilling",
    5 => "Finishing",
    6 => "Delivery"
  }.freeze

  STATUSES = [
    "Draft",
    "Posted",
    "In Progress",
    "Partially Completed",
    "Completed",
    "On Hold",
    "Cancelled"
  ].freeze

  validates :process_code, presence: true
  validates :process_name, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :stage_no, presence: true

  before_validation :set_process_name_and_stage_no

  def self.process_name_for(code)
    PROCESS_OPTIONS[code]
  end

  def self.stage_no_for(code)
    PROCESS_STAGES[code]
  end

  def self.stage_name_for(stage_no)
    STAGE_NAMES[stage_no]
  end

  def stage
    self.class.stage_no_for(process_code)
  end

  def stage_name
    self.class.stage_name_for(stage)
  end

  private

  def set_process_name_and_stage_no
    self.process_name = self.class.process_name_for(process_code)
    self.stage_no = stage
  end
end
