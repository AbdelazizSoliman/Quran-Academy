require "rails_helper"

RSpec.describe Notifications::E164Normalizer do
  it "normalizes an Egyptian local mobile number to E.164" do
    result = described_class.call("01012345678")
    expect(result).to be_valid
    expect(result.e164).to eq("+201012345678")
    expect(result.provider_address).to eq("201012345678")
  end

  it "accepts an Egyptian number already in international form without a plus" do
    result = described_class.call("201012345678")
    expect(result).to be_valid
    expect(result.provider_address).to eq("201012345678")
  end

  it "accepts an Egyptian number already in international form with a plus" do
    result = described_class.call("+201012345678")
    expect(result).to be_valid
    expect(result.provider_address).to eq("201012345678")
  end

  it "accepts the 00 international prefix" do
    result = described_class.call("00201012345678")
    expect(result).to be_valid
    expect(result.provider_address).to eq("201012345678")
  end

  it "strips harmless formatting characters" do
    result = described_class.call("+20 (101) 234-5678")
    expect(result).to be_valid
    expect(result.provider_address).to eq("201012345678")
  end

  it "preserves an already-valid non-Egyptian international number" do
    result = described_class.call("+966501234567")
    expect(result).to be_valid
    expect(result.provider_address).to eq("966501234567")
  end

  it "rejects a local-format number that is not a recognized Egyptian mobile prefix" do
    result = described_class.call("07911123456")
    expect(result).not_to be_valid
    expect(result.error).to eq(:invalid_phone)
  end

  it "does not invent a country code for an ambiguous short local number" do
    result = described_class.call("0123456")
    expect(result).not_to be_valid
    expect(result.error).to eq(:invalid_phone)
  end

  it "rejects blank and malformed values" do
    expect(described_class.call("").valid?).to be(false)
    expect(described_class.call("abc").valid?).to be(false)
    expect(described_class.call(nil).valid?).to be(false)
  end
end
