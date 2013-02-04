# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Mamertes::Parser do
  let(:application) {
    ::Mamertes::Application.new do
      command :abc do
        action do
          check = 1
        end

        command :def do
          action do |command|
            check = 2
          end
        end
      end

      option :boolean, ["b", "boolean"], help: "BOOLEAN"
      option :string, [nil, "string"], type: String, meta: "STRING", help: "STRING"
      option :integer, ["i", nil], type: Integer, help: "INTEGER"
      option :float, [nil, nil], type: Float, help: "FLOAT"
      option :array, ["a", "array"], type: Array, help: "ARRAY"
      option :choice, ["c", "choice"], type: String, help: "ARRAY", validator: ["yes", "no"]
      option :regexp, ["r", "regexp"], type: String, help: "REGEXP", validator: /yes|no/i
      option :action, ["A"] do |option, command|
        p "[OPTION] BLOCK"
      end
    end
  }

  let(:command) {
    c = ::Mamertes::Command.new
    c.application = application
    c
  }

  before(:each) do
    ENV["LANG"] = "en"
  end

  describe ".smart_join" do
    it "should correctly join arrays" do
      expect(::Mamertes::Parser.smart_join([])).to eq("")
      expect(::Mamertes::Parser.smart_join(["A"], ", ", " and ", nil)).to eq("A")
      expect(::Mamertes::Parser.smart_join(1, ", ", " and ", nil)).to eq("1")
      expect(::Mamertes::Parser.smart_join(["A", 1], ", ", " and ", nil)).to eq("A and 1")
      expect(::Mamertes::Parser.smart_join(["A", 1, true], ", ", " and ", nil)).to eq("A, 1 and true")
      expect(::Mamertes::Parser.smart_join(["A", "B", "C"], "-", " and ", nil)).to eq("A-B and C")
      expect(::Mamertes::Parser.smart_join(["A", "B", "C"], "-", "@", nil)).to eq("A-B@C")
      expect(::Mamertes::Parser.smart_join(["A", "B", "C"], ", ", " and ", "@")).to eq("@A@, @B@ and @C@")
    end
  end

  describe ".find_command" do
    it "should find commands" do
      args = ["A", "B", "C"]
      s1 = command.command("abc")
      s2 = command.command("abd")
      s1.command("def")

      expect(::Mamertes::Parser.find_command("abc", command, args)).to eq({name: "abc", args: args})
      expect(::Mamertes::Parser.find_command("abc:def", command, args)).to eq({name: "abc", args: ["def"] + args})
      expect(::Mamertes::Parser.find_command("abc def", command, args, " ")).to eq({name: "abc", args: ["def"] + args})
      expect(::Mamertes::Parser.find_command("d", s1, args)).to eq({name: "def", args: args})
      expect{ ::Mamertes::Parser.find_command("ab", command, args) }.to raise_error(::Mamertes::Error)
      expect(::Mamertes::Parser.find_command("abc", s2, args)).to be_nil
    end
  end

  describe ".parse" do
    it "should instantiate a parser and then parse" do
      ::Mamertes::Parser.should_receive(:new).and_call_original
      ::Mamertes::Parser.any_instance.should_receive(:parse).with("COMMAND", "ARGS")
      ::Mamertes::Parser.parse("COMMAND", "ARGS")
    end
  end

  describe "#parse" do
    it "should iterate options" do
      application.options.should_receive(:each_pair).exactly(2)
      ::Mamertes::Parser.parse(application, [])
    end

    it "should set good values" do
      application.options["boolean"].should_receive("set").with(true)
      application.options["string"].should_receive("set").with("A")
      application.options["integer"].should_receive("set").with(1)
      application.options["float"].should_receive("set").with(2.0)
      application.options["array"].should_receive("set").with(["B", "C"])
      application.options["choice"].should_receive("set").with("yes")
      application.options["regexp"].should_receive("set").with("no")
      application.options["action"].should_receive("execute_action")
      ::Mamertes::Parser.parse(application, ["-b", "-s", "A", "-i", "1", "-f", "2.0", "-a", "B,C", "-c", "yes", "-r", "no", "-A"])
    end

    it "should complain about invalid or additional values" do
      expect { ::Mamertes::Parser.parse(application, ["-b f"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-s"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-i", "A"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-f", "A"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-c", "B"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-r", "C"]) }.to raise_error(::Mamertes::Error)
      expect { ::Mamertes::Parser.parse(application, ["-R", "C"]) }.to raise_error(::Mamertes::Error)
      application.option("R", [], {required: true})
      expect { ::Mamertes::Parser.parse(application, ["-b"]) }.to raise_error(::Mamertes::Error) # Because we're missing a required option
    end

    it "should complain about duplicate options" do
      application.option(:boolean2)
      expect { ::Mamertes::Parser.parse(application, ["-b"]) }.to raise_error(::Mamertes::Error)
    end

    it "should return the command to execute" do
      expect(::Mamertes::Parser.parse(application, ["a", "OTHER"])).to eq({name: "abc", args: ["OTHER"]})
      expect(::Mamertes::Parser.parse(application, ["ab:d", "OTHER"])).to eq({name: "abc", args: ["d", "OTHER"]})
      expect(::Mamertes::Parser.parse(application, ["abc", "d", "OTHER"])).to eq({name: "abc", args: ["d", "OTHER"]})
      expect(::Mamertes::Parser.parse(application, ["d", "OTHER"])).to eq(nil)

      application.clear_options
      expect(::Mamertes::Parser.parse(application, ["a", "OTHER"])).to eq({name: "abc", args: ["OTHER"]})
      expect(::Mamertes::Parser.parse(application, ["d:d", "OTHER"])).to eq(nil)
      expect(::Mamertes::Parser.parse(application, ["d d", "OTHER"])).to eq(nil)
      expect(::Mamertes::Parser.parse(application, ["d", "d", "OTHER"])).to eq(nil)
    end
  end
end