# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
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
  let(:application) { ::Mamertes::Application.new(locale: :en) }

  describe "#initialize" do
    it "should call the parent constructor" do
      options = {a: :b}
      block = Proc.new {}

      expect(::Mamertes::Command).to receive(:new).with(options, &block)
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
      expect(application).to receive(:command).with(:help, {description: "Shows a help about a command."})
      expect(application).to receive(:option).with(:help, ["-h", "--help"], {help: "Shows this message."})
      application.help_option
    end

    it "should execute associated actions" do
      expect(application).to receive(:show_help).exactly(2)
      expect(application).to receive(:command_help)

      application.execute(["help", "command"])
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

      expect(application).to receive(:show_help)
      application.command_help(application)

      expect(command).to receive(:show_help)
      application.argument(command.name)
      application.command_help(application)

      expect(subcommand).to receive(:show_help)
      application.argument(subcommand.name)
      application.command_help(application)

      expect(subcommand).to receive(:show_help)
      application.argument("foo")
      application.command_help(application)
    end
  end

  describe "#run" do
    it "should forward to the shell" do
      expect(application.shell).to receive(:run).with("COMMAND", "MESSAGE", true, "A", false, false, "B")
      application.run("COMMAND", "MESSAGE", "A", "B")

      application.skip_commands = true
      application.output_commands = true
      application.show_commands = true
      expect(application.shell).to receive(:run).with("COMMAND", "MESSAGE", false, "C", true, true, "D")
      application.run("COMMAND", "MESSAGE", "C", "D")
    end
  end

  describe ".create" do
    it "should complain about a missing block" do
      expect { ::Mamertes::Application.create }.to raise_error(::Mamertes::Error)
    end

    it "should print errors" do
      allow(::Mamertes::Application).to receive(:create_application).and_raise(ArgumentError.new("ERROR"))
      expect(Kernel).to receive(:puts).with("ERROR")
      expect(Kernel).to receive(:exit).with(1)
      ::Mamertes::Application.create(__args__: []) {}
    end

    it "should create a default application" do
      expect(::Mamertes::Application).to receive(:new).with({name: "__APPLICATION__", parent: nil, application: nil, locale: :en})
      ::Mamertes::Application.create({locale: :en}) {}
    end

    it "should create an application with given options and block" do
      options = {name: "OK"}

      expect(::Mamertes::Application).to receive(:new).with({name: "OK", parent: nil, application: nil})
      application = ::Mamertes::Application.create(options) {}
    end

    it "should execute the block" do
      allow_any_instance_of(::Bovem::Console).to receive(:write)
      allow(Kernel).to receive(:exit)
      options = {name: "OK", __args__: []}
      check = false

      application = ::Mamertes::Application.create(options) { check = true }
      expect(check).to be_true
      expect(application.name).to eq("OK")
    end

    it "should execute the new application" do
      args = []

      application = ::Mamertes::Application.create do
        option("require", [], {})
        option("format", [], {})
        option("example", [], {})

        action do |command|
          args = command.arguments.join("-")
        end
      end

      expect(args).to eq(ARGV.reject {|a| a =~ /^--/ }.join("-"))
    end

    it "can override arguments" do
      args = []

      application = ::Mamertes::Application.create({__args__: ["C", "D"]}) do
        action do |command|
          args = command.arguments.join("-")
        end
      end

      expect(args).to eq("C-D")
    end

    it "should not execute the application if requested to" do
      args = []

      application = ::Mamertes::Application.create(run: false) do
        action do |command|
          args = command.arguments.join("-")
        end
      end

      expect(args).to eq([])
    end
  end
end