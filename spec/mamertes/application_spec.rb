# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Mamertes::Error do
  describe "#initialize" do
    it "copies attributes" do
      error = ::Mamertes::Error.new("A", "B", "C")
      expect(error.target).to eq("A")
      expect(error.reason).to eq("B")
      expect(error.message).to eq("C")
    end
  end
end

describe Mamertes::Application do
  let(:application) { ::Mamertes::Application.new }

  describe "#initialize" do
    it "should call the parent constructor" do
      options = {:a => :b}
      block = Proc.new {}

      ::Mamertes::Command.should_receive(:new).with(options, &block)
      ::Mamertes::Application.new(options, &block)
    end

    it "should set good defaults" do
      expect(application.shell).to eq(::Bovem::Shell.instance)
      expect(application.console).to eq(application.shell.console)
      expect(application.skip_commands).to be_false
      expect(application.show_commands).to be_false
      expect(application.output_commands).to be_false
    end
  end

  describe "#version" do
    it "should set and return the version" do
      expect(application.version).to be_nil
      expect(application.version("another")).to eq("another")
      expect(application.version(nil)).to eq("another")
    end
  end

  describe "#help_option" do
    it "should add a command and a option" do
      application.should_receive(:command).with(:help, {:description=>"Shows a help about a command."})
      application.should_receive(:option).with(:help, ["-h", "--help"], {:help=>"Shows this message."})
      application.help_option
    end

    it "should execute associated actions" do
      application.should_receive(:command_help)
      application.execute(["help", "command"])

      application.should_receive(:show_help)
      application.execute("-h")
    end
  end

  describe "#executable_name" do
    it "should return executable name" do
      expect(application.executable_name).to eq($0)
    end
  end

  describe "#command_help" do
    it "should show the help for the command" do
      command = application.command "command"
      subcommand = command.command "subcommand"

      application.should_receive(:show_help)
      application.command_help(application)

      command.should_receive(:show_help)
      application.argument(command.name)
      application.command_help(application)

      subcommand.should_receive(:show_help)
      application.argument(subcommand.name)
      application.command_help(application)

      subcommand.should_receive(:show_help)
      application.argument("foo")
      application.command_help(application)
    end
  end

  describe "#run" do
    it "should forward to the shell" do
      application.shell.should_receive(:run).with("COMMAND", "MESSAGE", true, "A", false, false, "B")
      application.run("COMMAND", "MESSAGE", "A", "B")

      application.skip_commands = true
      application.output_commands = true
      application.show_commands = true
      application.shell.should_receive(:run).with("COMMAND", "MESSAGE", false, "C", true, true, "D")
      application.run("COMMAND", "MESSAGE", "C", "D")
    end
  end
end

describe "Mamertes::App" do
  it "should complain about a missing block" do
    expect { ::Mamertes.App }.to raise_error(::Mamertes::Error)
  end

  it "should create a default application" do
    ::Mamertes::Application.should_receive(:new).with({:name => "__APPLICATION__", :parent => nil, :application => nil})
    ::Mamertes.App() do

    end
  end

  it "should create an application with given options and block" do
    options = {:name => "OK"}

    ::Mamertes::Application.should_receive(:new).with({:name => "OK", :parent => nil, :application => nil})
    application = ::Mamertes.App(options) {}
  end

  it "should create an application with given options and block" do
    options = {:name => "OK"}
    check = false

    application = ::Mamertes.App(options) { check = true }
    expect(check).to be_true
    expect(application.name).to eq("OK")
  end

  it "should execute the new application" do
    args = []

    application = ::Mamertes.App do
      action do |command|
        args = command.arguments.join("-")
      end
    end

    expect(args).to eq(ARGV.join("-"))

    application = ::Mamertes.App({:__args__ => ["C", "D"]}) do
      action do |command|
        args = command.arguments.join("-")
      end
    end

    expect(args).to eq("C-D")
  end
end