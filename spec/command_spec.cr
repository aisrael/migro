require "./spec_helper"
require "../src/command"

describe OptionPullParser do
  it "works" do
    opp = OptionPullParser.new %w[--url postgresql://admin:password@localhost --verbose up]
    opp.flag("url", expects_value: true)
    opp.flag("verbose")
    opp.args.size.should eq(4)
    opp.peek.should be_a(OptionPullParser::FlagWithValue)
    url = opp.read.as(OptionPullParser::FlagWithValue)
    url.value.should eq("postgresql://admin:password@localhost")
    opp.peek.should be_a(OptionPullParser::Flag)
    flag = opp.read.as(OptionPullParser::Flag)
    flag.name.should eq("verbose")
    opp.read.should eq("up")
  end

  describe "#peek" do
    it "returns the next token without consuming it" do
      opp = OptionPullParser.new %w[test]
      opp.peek.should eq("test")
      opp.args.size.should eq(1)
    end
  end

  describe "#read" do
    it "recognizes short flags" do
      opp = OptionPullParser.new %w[-v]
      opp.flag("version", short: "v")
      token = opp.read
      token.should be_a(OptionPullParser::Flag)
      token.as(OptionPullParser::Flag).name.should be("version")
    end
    it "recognizes long flags" do
      opp = OptionPullParser.new %w[-v]
      opp.flag("version", short: "v")
      token = opp.read
      token.should be_a(OptionPullParser::Flag)
      token.as(OptionPullParser::Flag).name.should be("version")
    end
    it "recognizes --long_flag=value" do
      opp = OptionPullParser.new %w[--url=test]
      opp.flag("url", expects_value: true)
      token = opp.read
      token.should be_a(OptionPullParser::FlagWithValue)
      flag = token.as(OptionPullParser::FlagWithValue)
      flag.name.should eq("url")
      flag.value.should eq("test")
    end
    it "can handle --long_flag <space> value" do
      opp = OptionPullParser.new %w[--url test]
      opp.flag("url", expects_value: true)
      token = opp.read
      token.should be_a(OptionPullParser::FlagWithValue)
      flag = token.as(OptionPullParser::FlagWithValue)
      flag.name.should eq("url")
      flag.value.should eq("test")
    end
  end

end
