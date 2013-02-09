# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Mamertes::Command do
  let(:application) {
    ::Mamertes::Application.new(locale: :en) {
      action {}
    }
  }

  let(:command) {
    c = ::Mamertes::Command.new(locale: :en)
    c.application = application
    c
  }

  describe "#initialize" do
    it "should forward to #setup_with" do
      expect(::Mamertes::Command.new(name: "command").name).to eq("command")
    end

    it "should call the block" do
      count = 0
      ::Mamertes::Command.new(name: "command") { count += 1 }
      expect(count).to eq(1)
    end
  end

  describe "#name" do
    it "should set and return the name" do
      expect(command.name).to be_nil
      expect(command.name("another")).to eq("another")
      expect(command.name(nil)).to eq("another")
    end
  end

  describe "#full_name" do
    it "should retrieve the full hierarchy of the name" do
      command.name = "root"
      expect(command.full_name).to eq("root")

      subcommand = ::Mamertes::Command.new(name: "child")
      subcommand.parent = command
      expect(subcommand.full_name).to eq("root:child")
      expect(subcommand.full_name(nil, " ")).to eq("root child")
      expect(subcommand.full_name("A", " ")).to eq("root child A")
    end
  end

  describe "#description" do
    it "should set and return the description" do
      expect(command.description).to be_nil
      expect(command.description("another")).to eq("another")
      expect(command.description(nil)).to eq("another")
    end
  end

  describe "#banner" do
    it "should set and return the banner" do
      expect(command.banner).to be_nil
      expect(command.banner("another")).to eq("another")
      expect(command.banner(nil)).to eq("another")
    end

  end

  describe "#synopsis" do
    it "should set and return the synopsis" do
      expect(command.synopsis).to be_nil
      expect(command.synopsis("another")).to eq("another")
      expect(command.synopsis(nil)).to eq("another")
    end
  end

  describe "#before" do
    it "should set and return the before hook" do
      valid = Proc.new{|a| puts "OK" }

      expect(command.before).to be_nil
      expect(command.before { puts "OK" }).to be_nil
      expect(command.before {|a, b| puts "OK" }).to be_nil
      expect(command.before(&valid)).to eq(valid)
    end
  end

  describe "#action" do
    it "should set and return the action" do
      valid = Proc.new{|a| puts "OK" }

      expect(command.action).to be_nil
      expect(command.action { puts "OK" }).to be_nil
      expect(command.action {|a, b| puts "OK" }).to be_nil
      expect(command.action(&valid)).to eq(valid)
    end
  end

  describe "#after" do
    it "should set and return the after hook" do
      valid = Proc.new{|a| puts "OK" }

      expect(command.after).to be_nil
      expect(command.after { puts "OK" }).to be_nil
      expect(command.after {|a, b| puts "OK" }).to be_nil
      expect(command.after(&valid)).to eq(valid)
    end
  end 

  describe "#has_description?" do
    it "should check if the command has a description" do
      expect(::Mamertes::Command.new.has_description?).to be_false
      expect(::Mamertes::Command.new({description: "DESCRIPTION"}).has_description?).to be_true
    end
  end

  describe "#has_banner?" do
    it "should check if the command has a banner" do
      expect(::Mamertes::Command.new.has_banner?).to be_false
      expect(::Mamertes::Command.new({banner: "BANNER"}).has_banner?).to be_true
    end
  end

  describe "#command" do
    it "should add a subcommand" do
      command.command("subcommand", {banner: "BANNER"}) do |option|
        description("DESCRIPTION")
      end

      subcommand = command.commands["subcommand"]

      expect(subcommand.name).to eq("subcommand")
      expect(subcommand.parent).to be(command)
      expect(subcommand.application).to be(application)
      expect(subcommand.banner).to eq("BANNER")
      expect(subcommand.description).to eq("DESCRIPTION")
    end

    it "should check for duplicates" do
      command.command("subcommand")
      expect {command.command("subcommand")}.to raise_error(::Mamertes::Error)
    end
  end

  describe "#option" do
    it "should add a subcommand" do
      command.option("option", ["short", "long"], {type: String, help: "HELP"})

      option = command.options["option"]

      expect(option.name).to eq("option")
      expect(option.short).to eq("s")
      expect(option.long).to eq("long")
      expect(option.help).to eq("HELP")
    end

    it "should check for duplicates" do
      application.option("option")
      command.option("option")
      expect {command.option("option")}.to raise_error(::Mamertes::Error)
      expect {application.option("option")}.to raise_error(::Mamertes::Error)
    end
  end

  describe "#commands" do
    it "should return the list of commands" do
      expect(command.commands).to eq({})
      command.command("subcommand1")
      command.command("subcommand2")
      expect(command.commands.values.collect(&:name).sort).to eq(["subcommand1", "subcommand2"])
    end

    it "should let access both with Symbol or String" do
      command.command("subcommand1")
      expect(command.commands).to be_a(HashWithIndifferentAccess)
      expect(command.commands[:subcommand1]).to eq(command.commands["subcommand1"])
    end
  end

  describe "#clear_commands" do
    it "should remove commands" do
      command.command("subcommand")
      expect(command.commands.length == 1)
      command.clear_commands
      expect(command.commands.length == 0)
    end
  end

  describe "#has_commands?" do
    it "should check if the command has subcommands" do
      expect(command.has_commands?).to be_false
      command.command("subcommand")
      expect(command.has_commands?).to be_true
    end
  end

  describe "#clear_options" do
    it "should remove options" do
      command.option("option")
      expect(command.options.length == 1)
      command.clear_options
      expect(command.options.length == 0)
    end
  end

  describe "#options" do
    it "should return the list of options" do
      expect(command.options).to eq({})
      command.option("option1")
      command.option("option2")
      expect(command.options.values.collect(&:name).sort).to eq(["option1", "option2"])
    end

    it "should let access both with Symbol or String" do
      command.option("option1")
      expect(command.options).to be_a(HashWithIndifferentAccess)
      expect(command.options[:option1]).to eq(command.options["option1"])
    end
  end

  describe "#has_options?" do
    it "should check if the command has options" do
      expect(command.has_options?).to be_false
      command.option("option")
      expect(command.has_options?).to be_true
    end
  end

  describe "#argument" do
    it "should add an argument to the command" do
      expect(command.arguments).to eq([])
      command.argument("A")
      expect(command.arguments).to eq(["A"])
      command.argument("B")
      expect(command.arguments).to eq(["A", "B"])
    end
  end

  describe "#arguments" do
    it "should return arguments" do
      expect(command.arguments).to eq([])
      command.argument("A")
      expect(command.arguments).to eq(["A"])
      command.argument("B")
      expect(command.arguments).to eq(["A", "B"])
    end
  end

  describe "#application" do
    it "should return the application" do
      expect(command.application).to be(application)
      expect(application.application).to be(application)
    end
  end

  describe "#is_application?" do
    it "should check if the command is an application" do
      expect(command.is_application?).to be_false
      expect(application.is_application?).to be_true
    end
  end

  describe "#setup_with" do
    it "should setup required option by calling proper methods" do
      command.should_receive("name").with("new-command")
      command.should_receive("application=").with(nil)
      command.setup_with({name: "new-command", application: nil, invalid: false})
    end
  end

  describe "#execute" do
    it "should parse command line" do
      Kernel.stub(:exit)
      ::Bovem::Console.any_instance.stub(:write)

      args = ["command"]
      ::Mamertes::Parser.should_receive(:parse).with(command, args)
      command.execute(args)
    end

    it "should execute hooks and actions in sequence" do
      check = []
      child = []
      args = ["command"]

      command.before do |command|
        check << "A"
      end

      command.action do |command|
        check << "B"
      end

      command.after do |command|
        check << "C"
      end

      command.command("subcommand") do
        before do |command|
          check << "D"
        end

        action do |command|
          check << "E"
        end

        after do |command|
          check << "F"
        end
      end

      ::Mamertes::Parser.stub(:parse).and_return(nil)
      command.execute(args)
      expect(check).to eq(["A", "B", "C"])
    end

    it "should skip its actions and hooks and pass control to the subcommand" do
      check = []
      child = []
      args = ["command"]

      command.before do |command|
        check << "A"
      end

      command.action do |command|
        check << "B"
      end

      command.after do |command|
        check << "C"
      end

      command.command("subcommand") do
        before do |command|
          check << "D"
        end

        action do |command|
          check << "E"
        end

        after do |command|
          check << "F"
        end
      end

      ::Mamertes::Parser.stub(:parse) do |cmd, args|
        cmd == command ? {name: "subcommand", args: args} : nil
      end
      command.execute(args)
      expect(check).to eq(["D", "E", "F"])
    end

    it "should show help if action is not defined and no subcommand is found" do
      check = []
      child = []
      args = ["command"]

      command.command("subcommand") do
        before do |command|
          check << "D"
        end

        action do |command|
          check << "E"
        end

        after do |command|
          check << "F"
        end
      end

      ::Mamertes::Parser.stub(:parse).and_return(nil)
      command.should_receive(:show_help)
      command.execute(args)
      expect(check).to eq([])
    end
  end

  describe "#get_options" do
    let(:reference){
      c = ::Mamertes::Command.new("command") do
        option("aaa", [], {type: Integer, default: 456})
        option("bbb", [], {type: String})
        option("ccc", [], {type: Array, default: ["1", "2"]})
      end

      c.application = ::Mamertes::Application.new do |a|
        option("aaa", [], {type: Integer, default: 123})
        option("ddd", [], {type: Float})
        action {}
      end

      c
    }

    it "should return the full list of options" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options.symbolize_keys).to eq({application_aaa: 111, application_ddd: 2.0, aaa: 456, bbb: "2.0", ccc: ["A", "B", "C"]})
    end

    it "should only return provided options if required to" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111"])
      Mamertes::Parser.parse(reference, ["--ccc", "2.0"])
      expect(reference.get_options(false).symbolize_keys).to eq({application_aaa: 111, aaa: 456, ccc: ["2.0"]})
    end

    it "should skip application options if required to" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options(true, false).symbolize_keys).to eq({aaa: 456, bbb: "2.0", ccc: ["A", "B", "C"]})
      expect(reference.get_options(true, nil).symbolize_keys).to eq({aaa: 456, bbb: "2.0", ccc: ["A", "B", "C"]})
    end

    it "should apply the requested prefix for command options" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options(true, false, "PREFIX").symbolize_keys).to eq({PREFIXaaa: 456, PREFIXbbb: "2.0", PREFIXccc: ["A", "B", "C"]})
    end

    it "should apply the requested prefix for application options" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options(true, "APP").symbolize_keys).to eq({APPaaa: 111, APPddd: 2.0, aaa: 456, bbb: "2.0", ccc: ["A", "B", "C"]})
    end

    it "should only return requested options" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options(true, "application_", "", :aaa, :bbb).symbolize_keys).to eq({application_aaa: 111, aaa: 456, bbb: "2.0"})
    end

    it "should apply higher precedence to command options in case of conflicts" do
      Mamertes::Parser.parse(reference.application, ["--aaa", "111", "--ddd", "2.0"])
      Mamertes::Parser.parse(reference, ["--bbb", "2.0", "--ccc", "A,B,C"])
      expect(reference.get_options(true, "", "").symbolize_keys).to eq({ddd: 2.0, aaa: 456, bbb: "2.0", ccc: ["A", "B", "C"]})
    end
  end

  describe "#show_help" do
    it "should behave differently for application" do
      Kernel.stub(:exit).and_return(0)

      application.console.should_receive(:write).with("[NAME]")
      application.console.should_receive(:write).at_least(0)
      application.show_help
    end

    it "should print a banner" do
      Kernel.stub(:exit).and_return(0)

      command.banner = "BANNER"
      application.console.should_receive(:write).with("[DESCRIPTION]")
      application.console.should_receive(:write).at_least(0)
      command.show_help
    end

    it "should print options" do
      Kernel.stub(:exit).and_return(0)

      application.option("global", [], {type: String})
      command.option("local")

      application.console.should_receive(:write).with("[GLOBAL OPTIONS]")
      application.console.should_receive(:write).with("[OPTIONS]")
      application.console.should_receive(:write).at_least(0)
      application.show_help
      command.show_help
    end

    it "should print subcommands" do
      Kernel.stub(:exit).and_return(0)

      command.command("subcommand")
      application.console.should_receive(:write).with("[COMMANDS]")
      application.console.should_receive(:write).with("[SUBCOMMANDS]")
      application.console.should_receive(:write).at_least(0)
      application.show_help
      command.show_help
    end

    it "should exit" do
      ::Bovem::Console.any_instance.stub(:write)

      Kernel.should_receive(:exit).with(0).exactly(1)
      application.show_help
    end
  end
end