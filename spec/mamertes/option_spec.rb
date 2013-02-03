# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Mamertes::Option do
  let(:option) { ::Mamertes::Option.new("NAME") }

  describe "#initialize" do
    it "should set good forms" do
      option = ::Mamertes::Option.new("NAME")
      expect(option.name).to eq("NAME")
      expect(option.short).to eq("N")
      expect(option.long).to eq("NAME")

      option = ::Mamertes::Option.new("NAME", "O")
      expect(option.name).to eq("NAME")
      expect(option.short).to eq("O")
      expect(option.long).to eq("NAME")

      option = ::Mamertes::Option.new("NAME", ["O", "OPTION"])
      expect(option.name).to eq("NAME")
      expect(option.short).to eq("O")
      expect(option.long).to eq("OPTION")

    end

    it "should set options" do
      option = ::Mamertes::Option.new("NAME", ["O", "OPTION"], {required: true, help: "HELP", unused: "UNUSED"})
      expect(option.help).to be_true
      expect(option.help).to eq("HELP")
    end
  end

  describe "#short=" do
    it "should set good form" do
      option.short = "a"
      expect(option.short).to eq("a")

      option.short = "-b"
      expect(option.short).to eq("b")

      option.short = "-c"
      expect(option.short).to eq("c")

      option.short = 1
      expect(option.short).to eq("1")

      option.short = true
      expect(option.short).to eq("t")

      option.short = nil
      expect(option.short).to eq("N")
    end
  end

  describe "#long=" do
    it "should set good form" do
      option.long = "a"
      expect(option.long).to eq("a")

      option.long = "abc"
      expect(option.long).to eq("abc")

      option.long = "-def"
      expect(option.long).to eq("def")

      option.long = "--ghi"
      expect(option.long).to eq("ghi")

      option.long = true
      expect(option.long).to eq("true")

      option.long = 1
      expect(option.long).to eq("1")

      option.long = nil
      expect(option.long).to eq("NAME")
    end
  end

  describe "#validator=" do
    it "should set a good validator" do
      option.validator = "VALUE"
      expect(option.validator).to eq(["VALUE"])
      option.validator = ["VALUE", "VALUE"]
      expect(option.validator).to eq(["VALUE", "VALUE"])
      option.validator = /VALUE/
      expect(option.validator).to eq(/VALUE/)
      option.validator = nil
      expect(option.validator).to be_nil
      option.validator = ""
      expect(option.validator).to be_nil
      option.validator = []
      expect(option.validator).to be_nil
      option.validator = //
      expect(option.validator).to be_nil
    end
  end

  describe "#complete_short" do
    it "should return a good short form" do
      expect(::Mamertes::Option.new("NAME").complete_short).to eq("-N")
      expect(::Mamertes::Option.new("NAME", "A").complete_short).to eq("-A")
      expect(::Mamertes::Option.new("NAME", ["A", "BC"]).complete_short).to eq("-A")
      expect(::Mamertes::Option.new("NAME", [true, false]).complete_short).to eq("-t")
    end
  end

  describe "#complete_long" do
    it "should return a good short form" do
      expect(::Mamertes::Option.new("NAME").complete_long).to eq("--NAME")
      expect(::Mamertes::Option.new("NAME", "A").complete_long).to eq("--NAME")
      expect(::Mamertes::Option.new("NAME", ["A", "BC"]).complete_long).to eq("--BC")
      expect(::Mamertes::Option.new("NAME", [true, true]).complete_long).to eq("--true")
    end
  end

  describe "#label" do
    it "should return a good label" do
      expect(::Mamertes::Option.new("NAME").label).to eq("-N/--NAME")
      expect(::Mamertes::Option.new("NAME", "A").label).to eq("-A/--NAME")
      expect(::Mamertes::Option.new("NAME", ["A", "BC"]).label).to eq("-A/--BC")
      expect(::Mamertes::Option.new("NAME", [true, true]).label).to eq("-t/--true")
    end

  end

  describe "#meta" do
    it "should return the option meta" do
      expect(::Mamertes::Option.new("NAME", []).meta).to be_nil
      expect(::Mamertes::Option.new("NAME", [], {type: String}).meta).to eq("NAME")
      expect(::Mamertes::Option.new("foo", [], {type: String}).meta).to eq("FOO")
      expect(::Mamertes::Option.new("NAME", [], {type: String, meta: "STRING"}).meta).to eq("STRING")
    end
  end

  describe "#set" do
    it "should set the value" do
      expect(option.set("VALUE")).to be_true
      expect(option.value).to eq("VALUE")
      expect(option.provided?).to be_true
    end

    it "should match against a regexp validator" do
      option.validator = /^A|B$/

      expect{ option.set("VALUE") }.to raise_error(::Mamertes::Error)
      expect(option.value).to be_false
      expect(option.provided?).to be_false

      expect(option.set("VALUE", false)).to be_false
      expect(option.value).to be_false
      expect(option.provided?).to be_false

      option.set("A")
      expect(option.value).to eq("A")
      expect(option.provided?).to be_true

      option.set("B")
      expect(option.value).to eq("B")
      expect(option.provided?).to be_true
    end

    it "should match against an array validator" do
      option.validator = ["A", "B"]

      expect{ option.set("VALUE") }.to raise_error(::Mamertes::Error)
      expect(option.value).to be_false
      expect(option.provided?).to be_false

      expect(option.set("VALUE", false)).to be_false
      expect(option.value).to be_false
      expect(option.provided?).to be_false

      option.set("A")
      expect(option.value).to eq("A")
      expect(option.provided?).to be_true

      option.set("B")
      expect(option.value).to eq("B")
      expect(option.provided?).to be_true
    end
  end

  describe "#execute_action" do
    it "should execute action if provided" do
      check = false
      option = ::Mamertes::Option.new("NAME") { |a,b| check = true }
      option.execute_action

      expect(check).to be_true
      expect(option.provided?).to be_true
    end

    it "should result in a no-op if the action is missing or doesn't take enough arguments" do
      option.execute_action
      expect(option.provided?).to be_false

      option = ::Mamertes::Option.new("NAME") { check = true }
      expect(option.provided?).to be_false
    end
  end

  describe "#requires_argument?" do
    it "should check if the option requires argument" do
      expect(::Mamertes::Option.new("NAME", []).requires_argument?).to be_false
      expect(::Mamertes::Option.new("NAME", [], {type: String}).requires_argument?).to be_true
      expect(::Mamertes::Option.new("NAME", [], {type: Integer}).requires_argument?).to be_true
      expect(::Mamertes::Option.new("NAME", [], {type: Float}).requires_argument?).to be_true
      expect(::Mamertes::Option.new("NAME", [], {type: Array}).requires_argument?).to be_true
      expect(::Mamertes::Option.new("NAME").requires_argument?).to be_false
    end
  end

  describe "#provided?" do
    it "should check if the option was provided" do
      expect(::Mamertes::Option.new("NAME").provided?).to be_false
      option.set(true)
      expect(option.provided?).to be_true
    end
  end

  describe "#has_help?" do
    it "should check if the option has a help" do
      expect(::Mamertes::Option.new("NAME").has_help?).to be_false
      expect(::Mamertes::Option.new("NAME", [], help: "HELP").has_help?).to be_true
    end
  end

  describe "#value" do
    it "should return the set value" do
      option.default = "DEFAULT VALUE"
      expect(option.value).to eq("DEFAULT VALUE")

      option.default = nil
      expect(option.value).to be_false

      option.set(true)
      expect(option.value).to be_true

      option.set("VALUE")
      expect(option.value).to eq("VALUE")
    end

    it "should return good defaults" do
      expect(::Mamertes::Option.new("NAME").value).to be_false
      expect(::Mamertes::Option.new("NAME", [], {type: Regexp}).value).to be_false
      expect(::Mamertes::Option.new("NAME", [], {type: String}).value).to eq("")
      expect(::Mamertes::Option.new("NAME", [], {type: Integer}).value).to eq(0)
      expect(::Mamertes::Option.new("NAME", [], {type: Float}).value).to eq(0.0)
      expect(::Mamertes::Option.new("NAME", [], {type: Array}).value).to eq([])
    end
  end
end