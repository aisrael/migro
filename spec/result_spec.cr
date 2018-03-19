require "./spec_helper"
require "../src/result"

def succeeds : Result(String)
  Success(String).new("It works!")
end

def fails : Result(String)
  Failure(String).new("It failed.")
end

describe "Result" do
  it "handles success" do
    result = succeeds()
    result.value.should eq("It works!")
  end
  it "handles failure" do
    result = fails()
    result.message.should eq("It failed.")
  end
end
