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
    # The name of the command.
    #
    # At runtime you can invoke it using the minimum number of letters to uniquely distinguish it from others.
    attr_accessor :name

    # A very short description of what this command does.
    attr_accessor :description

    # A long description of the command.
    attr_accessor :banner

    # A synopsis of the typical command line usage.
    attr_accessor :synopsis

    # A hook to execute before the command's action. It is executed only if no subcommand is executed.
    attr_accessor :before

    # The action of the command. It is executed only if no subcommand is executed.
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
    # @param options [Hash] The new options to initialize the command with.
    def initialize(options, &block)
      self.setup_with(options)
      self.instance_eval(&block) if block_given?
    end

    # Reads and optionally sets the name of the command.
    #
    # @param value [NilClass|Object] The new name of the command.
    # @return [String] The name of the command.
    def name(value = nil)
      @name = value if !value.nil?
      @name
    end

    # Gets a full name, that is the name of the command and its ancestor. Optionally it also appends a suffix
    #
    # @param suffix [String] A suffix to append.
    # @param separator [String] The separator to use for components.
    # @return [String] The full name.
    def full_name(suffix = nil, separator = ":")
      if self.is_application? then
        nil
      else
        [self.parent ? self.parent.full_name(nil, separator) : nil, !self.is_application? ? self.name : nil, suffix].compact.join(":")
      end
    end

    # Reads and optionally sets the short description of the command.
    #
    # @param value [NilClass|Object] The new short description of the command.
    # @return [String] The short description of the command.
    def description(value = nil)
      @description = value if !value.nil?
      @description
    end

    # Reads and optionally sets the description of the command.
    #
    # @param value [NilClass|Object] The new description of the command.
    # @return [String] The description of the command.
    def banner(value = nil)
      @banner = value if !value.nil?
      @banner
    end

    # Reads and optionally sets the synopsis of the command.
    #
    # @param value [NilClass|Object] The new synopsis of the command.
    # @return [String] The synopsis of the command.
    def synopsis(value = nil)
      @synopsis = value if !value.nil?
      @synopsis
    end

    # Sets the before hook, that is a block executed before the action of the command.
    #
    # It is executed only if no subcommand is executed.
    #
    # @return [Proc|NilClass] The before hook of the command.
    def before(&hook)
      @before = hook if block_given? && hook.arity == 1
      @before
    end

    # Sets the action of the command.
    #
    # It is executed only if no subcommand is executed.
    #
    # @return [Proc|NilClass] The action of the command.
    def action(&hook)
      @action = hook if block_given? && hook.arity == 1
      @action
    end

    # Sets the after hook, that is a block executed after the action of the command.
    #
    # It is executed only if no subcommand is executed.
    #
    # @return [Proc|NilClass] The after hook of the command.
    def after(&hook)
      @after = hook if block_given? && hook.arity == 1
      @after
    end

    # Adds a new subcommand to this command.
    #
    # @param name [String] The name of the command. Must be unique.
    # @param options [Hash] A set of options for this command
    def command(name, options = {}, &block)
      @commands ||= {}

      options = {} if !options.is_a?(::Hash)
      options = {:name => name.to_s, :parent => self, :application => self.application}.merge(options)

      raise Mamertes::Error.new(self, :duplicate_command, "The command \"#{self.full_name(name)}\" already exists.") if @commands[name.to_s]
      @commands[name.to_s] = ::Mamertes::Command.new(options, &block)
    end

    # Adds a new option to this command.
    #
    # @param name [String] The name of the option. Must be unique.
    # @param forms [Array] An array of short and long forms for this option.
    # @param options [Hash] A set of options for this option.
    # @param action [Proc] An optional action to pass to the option.
    def option(name, forms = [], options = {}, &action)
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
    end

    # Returns the list of options of this command.
    #
    # @return [Hash] The list of options of this command.
    def options
      @options || {}
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

    # Checks if the command is an application
    #
    # @return [Boolean] `true` if command is an application, `false` otherwise.
    def is_application?
      self.is_a?(Mamertes::Application)
    end

    # Setups the command.
    #
    # @param options [Hash] A set of options to set for the command
    # @return [Command] The command.
    def setup_with(options = {})
      options = {} if !options.is_a?(::Hash)

      options.each_pair do |option, value|
        method = option.to_s

        if self.respond_to?(method) && self.method(method).arity == 1 then
          self.send(method, value)
        elsif self.respond_to?(method + "=")
          self.send(method + "=", value)
        end
      end

      self
    end

    # Execute the command, running its action or a subcommand.
    def execute(args)
      subcommand = Mamertes::Parser.parse(self, args)

      if subcommand.nil? && self.action then # We have an action, we won't call subcommand.
        # Run the before hook
        self.before.call(self) if self.before

        # Run the action
        self.action.call(self) if self.action

        # Run the after hook
        self.before.call(self) if self.after
      else
        self.commands[subcommand[:name]].execute(subcommand[:args])
      end
    end
  end
end