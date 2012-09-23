# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # This class represent a command (action) for Mamertes.
  #
  # Every command has the execution block and a set of option. Optionally, it also has before and after hooks.
  class Command
    # The name of this command.
    #
    # At runtime you can invoke it using the minimum number of letters to uniquely distinguish it from others.
    attr_accessor :name

    # A very short description of what this command does.
    attr_accessor :description

    # A long description of this command.
    attr_accessor :banner

    # A synopsis of the typical command line usage.
    attr_accessor :synopsis

    # A hook to execute before the command's action. It is executed only if no subcommand is executed.
    attr_accessor :before

    # The action of this command. It is executed only if no subcommand is executed.
    attr_accessor :action

    # A hook to execute after the command's action. It is executed only if no subcommand is executed.
    attr_accessor :after

    # The application this command belongs to.
    attr_accessor :application

    # The parent of this command.
    attr_accessor :parent

    # The subcommands associated to this command.
    attr_reader :commands

    # The options available for this command.
    attr_reader :options

    # The arguments provided to this command.
    attr_reader :arguments

    # Creates a new command.
    #
    # @param options [Hash] The settings to initialize the command with.
    def initialize(options = {}, &block)
      self.setup_with(options)
      self.instance_eval(&block) if block_given?
    end

    # Reads and optionally sets the name of this command.
    #
    # @param value [NilClass|Object] The new name of this command.
    # @return [String] The name of this command.
    def name(value = nil)
      @name = value if !value.nil?
      @name
    end

    # Gets a full name, that is the name of this command and its ancestor. Optionally it also appends a suffix
    #
    # @param suffix [String] A suffix to append.
    # @param separator [String] The separator to use for components.
    # @return [String] The full name.
    def full_name(suffix = nil, separator = ":")
      if self.is_application? then
        nil
      else
        [self.parent ? self.parent.full_name(nil, separator) : nil, !self.is_application? ? self.name : nil, suffix].compact.join(separator)
      end
    end

    # Reads and optionally sets the short description of this command.
    #
    # @param value [NilClass|Object] The new short description of this command.
    # @return [String] The short description of this command.
    def description(value = nil)
      @description = value if !value.nil?
      @description
    end

    # Reads and optionally sets the description of this command.
    #
    # @param value [NilClass|Object] The new description of this command.
    # @return [String] The description of this command.
    def banner(value = nil)
      @banner = value if !value.nil?
      @banner
    end

    # Reads and optionally sets the synopsis of this command.
    #
    # @param value [NilClass|Object] The new synopsis of this command.
    # @return [String] The synopsis of this command.
    def synopsis(value = nil)
      @synopsis = value if !value.nil?
      @synopsis
    end

    # Reads and optionally sets the before hook, that is a block executed before the action of this command.
    #
    # This hook is only executed if no subcommand is executed.
    #
    # @return [Proc|NilClass] The before hook of this command.
    def before(&hook)
      @before = hook if block_given? && hook.arity == 1
      @before
    end

    # Reads and optionally sets the action of this command.
    #
    # A command action is only executed if no subcommand is executed.
    #
    # @return [Proc|NilClass] The action of this command.
    def action(&hook)
      @action = hook if block_given? && hook.arity == 1
      @action
    end

    # Sets the after hook, that is a block executed after the action of this command.
    #
    # This hook is only executed if no subcommand is executed.
    #
    # @return [Proc|NilClass] The after hook of this command.
    def after(&hook)
      @after = hook if block_given? && hook.arity == 1
      @after
    end

    # Check if this command has a description.
    #
    # @return [Boolean] `true` if this command has a description, `false` otherwise.
    def has_description?
      self.description.present?
    end

    # Check if this command has a banner.
    #
    # @return [Boolean] `true` if this command has a banner, `false` otherwise.
    def has_banner?
      self.banner.present?
    end

    # Adds a new subcommand to this command.
    #
    # @param name [String] The name of this command. Must be unique.
    # @param options [Hash] A set of options for this command.
    # @return [Command] The newly added command.
    def command(name, options = {}, &block)
      @commands ||= {}

      options = {} if !options.is_a?(::Hash)
      options = {:name => name.to_s, :parent => self, :application => self.application}.merge(options)

      raise Mamertes::Error.new(self, :duplicate_command, "The command \"#{self.full_name(name)}\" already exists.") if @commands[name.to_s]

      command = ::Mamertes::Command.new(options, &block)

      # Add the help option
      command.option(:help, ["-h", "--help"], :help => "Shows this message."){|command, option| command.show_help }

      @commands[name.to_s] = command
      command
    end

    # Adds a new option to this command.
    #
    # @see Option#initialize
    #
    # @param name [String] The name of the option. Must be unique.
    # @param forms [Array] An array of short and long forms for this option.
    # @param options [Hash] The settings for the option.
    # @param action [Proc] An optional action to pass to the option.
    # @return [Option] The newly added option.
    def option(name, forms = [], options = {}, &action)
      name = name.ensure_string
      @options ||= {}

      if @options[name] then
        if self.is_application? then
          raise Mamertes::Error.new(self, :duplicate_option, "The global option \"#{name}\" already exists.")
        else
          raise Mamertes::Error.new(self, :duplicate_option, "The option \"#{name}\" already exists for the command \"#{self.full_name}\".")
        end
      end

      option = ::Mamertes::Option.new(name, forms, options, &action)
      option.parent = self
      @options[name] = option
      option
    end

    # Returns the list of subcommands of this command.
    #
    # @return [Hash] The list of subcommands of this command.
    def commands
      @commands || {}
    end

    # Clear all subcommands of this commands.
    # @return [Hash] The new (empty) list of subcommands of this command.
    def clear_commands
      @commands = {}
    end

    # Check if this command has subcommands.
    #
    # @return [Boolean] `true` if this command has subcommands, `false` otherwise.
    def has_commands?
      self.commands.length > 0
    end

    # Returns the list of options of this command.
    #
    # @return [Hash] The list of options of this command.
    def options
      @options || {}
    end

    # Clear all the options of this commands.
    # @return [Hash] The new (empty) list of the options of this command.
    def clear_options
      @options = {}
    end

    # Check if this command has options.
    #
    # @return [Boolean] `true` if this command has options, `false` otherwise.
    def has_options?
      self.options.length > 0
    end

    # Adds a new argument to this command.
    #
    # @param value [String] The argument to add.
    def argument(value)
      @args ||= []
      @args << value
    end

    # Returns the list of arguments of this command.
    #
    # @return [Array] The list of arguments of this command.
    def arguments
      @args || []
    end

    # Returns the application this command belongs to.
    #
    # @return [Application] The application this command belongs to or `self`, if the command is an Application.
    def application
      self.is_application? ? self : @application
    end

    # Checks if the command is an application.
    #
    # @return [Boolean] `true` if command is an application, `false` otherwise.
    def is_application?
      self.is_a?(Mamertes::Application)
    end

    # Setups the command.
    #
    # @param options [Hash] The setttings for this command.
    # @return [Command] The command.
    def setup_with(options = {})
      options = {} if !options.is_a?(::Hash)

      options.each_pair do |option, value|
        method = option.to_s

        if self.respond_to?(method) && self.method(method).arity != 0 then
          self.send(method, value)
        elsif self.respond_to?(method + "=") then
          self.send(method + "=", value)
        end
      end

      self
    end

    # Execute this command, running its action or a subcommand.
    #
    # @param args [Array] The arguments to pass to the command.
    def execute(args)
      subcommand = Mamertes::Parser.parse(self, args)

      if subcommand.nil? && self.action then # We have an action, we won't call subcommand.
        # Run the before hook
        self.before.call(self) if self.before

        # Run the action
        self.action.call(self) if self.action

        # Run the after hook
        self.after.call(self) if self.after
      elsif subcommand.present? then
        self.commands[subcommand[:name]].execute(subcommand[:args])
      end
    end

    # Shows a help about this command.
    def show_help
      console = self.is_application? ? self.console : self.application.console

      if self.is_application? then
        # Application
        console.write("[NAME]")
        console.write("%s %s%s" % [self.name, self.version, self.has_description? ? " - " + self.description : ""], "\n", 4, true)
        console.write("")
        console.write("[SYNOPSIS]")
        console.write(self.synopsis.present? ? self.synopsis : "%s [options] %s[command-options] [arguments] " % [self.executable_name, self.has_commands? ? "[command [subcommand ...]]" : ""], "\n", 4, true)
      else
        console.write("[SYNOPSIS]")
        console.write(self.synopsis.present? ? self.synopsis : "%s [options] %s [subcommand ...] [command-options] [arguments] " % [self.application.executable_name, self.full_name(nil, " "), self.has_commands? ? "[command [subcommand ...]]" : ""], "\n", 4, true)
      end

      if self.has_banner? then
        console.write("")
        console.write("[DESCRIPTION]")
        console.write(self.banner, "\n", 4, true)
      end

      # Global options
      if self.has_options? then
        console.write("")
        console.write(self.is_application? ? "[GLOBAL OPTIONS]" : "[OPTIONS]")

        # First of all, grab all options and construct labels
        lefts = {}
        self.options.each_value do |option|
          left = [option.complete_short, option.complete_long]

          if option.requires_argument? then
            left[0] += " " + option.meta
            left[1] += " " + option.meta
          end

          lefts[left.join(", ")] = option.has_help? ? option.help : "*NO DESCRIPTION PROVIDED*"
        end

        alignment = lefts.keys.collect(&:length).max

        console.with_indentation(4) do
          lefts.keys.sort.each do |head|
            help = lefts[head]
            console.write("%s - %s" % [head.ljust(alignment, " "), help], "\n", true, true)
          end
        end
      end

      # Commands
      if self.has_commands? then
        console.write("")
        console.write(self.is_application? ? "[COMMANDS]" : "[SUBCOMMANDS]")

        # Find the maximum lenght of the commands
        alignment = self.commands.keys.collect(&:length).max

        console.with_indentation(4) do
          self.commands.keys.sort.each do |name|
            command = self.commands[name]
            console.write("%s - %s" % [name.ljust(alignment, " "), command.description.present? ? command.description : "*NO DESCRIPTION PROVIDED*"], "\n", true, true)
          end
        end
      end

      Kernel.exit(0)
    end
  end
end