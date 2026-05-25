class JobProcess < ApplicationRecord
  belongs_to :job

  PROCESS_OPTIONS = {
    "PRODRAFT" => "Drafting",
    "PROCUT" => "Miter Saw Cutting",
    "PENTLMS" => "Tube Laser - Mild Steel",
    "PROFLMS" => "Flat Bed Laser - Mild Steel",
    "PROPB" => "Press Brake",
    "PRODRILL" => "Drilling / Punching",
    "PROFAB" => "Fabrication / Assembly",
    "PROFLAL" => "Flat Bed Laser - Aluminium",
    "PROFLSS" => "Flat Bed Laser - Stainless Steel",
    "PROGUIL" => "Guillotine",
    "PROPRIME" => "Priming",
    "PENPRIME" => "Penrith Priming",
    "PRORO" => "Rolling",
    "PROPAINTYELLOW" => "Yellow Enamel Painting",
    "GAS" => "Galvanizing",
    "PRODEL" => "Delivery"
  }.freeze

  PROCESS_STAGES = {
    "PRODRAFT" => 1,

    "PROCUT" => 2,
    "PENTLMS" => 2,
    "PROFLMS" => 2,
    "PROFLAL" => 2,
    "PROFLSS" => 2,
    "PROGUIL" => 2,

    "PROPB" => 3,
    "PRORO" => 3,

    "PROFAB" => 4,
    "PRODRILL" => 4,

    "PROPRIME" => 5,
    "PENPRIME" => 5,
    "PROPAINTYELLOW" => 5,
    "GAS" => 5,

    "PRODEL" => 6
  }.freeze

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
    "Waiting",
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

  def stage_name
    self.class.stage_name_for(stage_no)
  end

  private

  def set_process_name_and_stage_no
    self.process_name = self.class.process_name_for(process_code)
    self.stage_no = self.class.stage_no_for(process_code)
  end
end