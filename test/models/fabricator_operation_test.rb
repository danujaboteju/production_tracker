require "test_helper"

class FabricatorOperationTest < ActiveSupport::TestCase
  setup do
    @fabricator = Fabricator.create!(name: "Operation Test Member")
  end

  test "operation code is required" do
    operation = @fabricator.fabricator_operations.build(operation_code: "")

    assert_not operation.valid?
    assert_includes operation.errors[:operation_code], "can't be blank"
  end

  test "operation code must be a known job process code" do
    operation = @fabricator.fabricator_operations.build(operation_code: "UNKNOWN")

    assert_not operation.valid?
    assert_includes operation.errors[:operation_code], "is not included in the list"
  end

  test "person cannot be assigned to the same operation twice" do
    @fabricator.fabricator_operations.create!(operation_code: "PROFAB")
    duplicate = @fabricator.fabricator_operations.build(operation_code: "PROFAB")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:operation_code], "has already been taken"
  end
end
