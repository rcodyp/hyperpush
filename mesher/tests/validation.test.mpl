# Unit tests for Ingestion.Validation pure functions.
# No database or actor dependencies.
# Run with: meshc test mesher/tests/

from Ingestion.Validation import validate_level, validate_payload_size, validate_bulk_count

describe("validate_level") do
  test("accepts fatal") do
    assert_eq(validate_level("fatal"), Ok("valid"))
  end

  test("accepts error") do
    assert_eq(validate_level("error"), Ok("valid"))
  end

  test("accepts warning") do
    assert_eq(validate_level("warning"), Ok("valid"))
  end

  test("accepts info") do
    assert_eq(validate_level("info"), Ok("valid"))
  end

  test("accepts debug") do
    assert_eq(validate_level("debug"), Ok("valid"))
  end

  test("rejects critical") do
    let result = validate_level("critical")
    case result do
      Err(_) -> assert(true)
      Ok(_) -> assert(false)
    end
  end

  test("rejects empty string") do
    let result = validate_level("")
    case result do
      Err(_) -> assert(true)
      Ok(_) -> assert(false)
    end
  end
end

describe("validate_payload_size") do
  test("accepts body within limit") do
    assert_eq(validate_payload_size("hello", 100), Ok("ok"))
  end

  test("accepts body exactly at limit") do
    assert_eq(validate_payload_size("hello", 5), Ok("ok"))
  end

  test("rejects body over limit") do
    let result = validate_payload_size("hello world", 5)
    case result do
      Err(_) -> assert(true)
      Ok(_) -> assert(false)
    end
  end
end

describe("validate_bulk_count") do
  test("accepts count within limit") do
    assert_eq(validate_bulk_count(50, 100), Ok("ok"))
  end

  test("accepts count exactly at limit") do
    assert_eq(validate_bulk_count(100, 100), Ok("ok"))
  end

  test("rejects count over limit") do
    let result = validate_bulk_count(101, 100)
    case result do
      Err(_) -> assert(true)
      Ok(_) -> assert(false)
    end
  end
end
