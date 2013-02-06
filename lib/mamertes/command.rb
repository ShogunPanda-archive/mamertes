# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # Methods for the {Command Command} class.
  module CommandMethods
    # Methods for showing help messages.
    module Help
      # Shows a help about this command.
      def show_help
        console = self.is_application? ? self.console : self.application.console
        self.is_application? ? show_help_application_summary(console) : show_help_command_summary(console)
        show_help_banner(console) if self.has_banner?
        show_help_options(console) if self.has_options?
        show_help_commands(console) if self.has_commands?
        Kernel.exit(0)
      end

      private
        # Prints a help summary about the application.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_application_summary(console)
          # Application
          console.write(self.i18n.help_name)
          console.write("%s %s%s" % [self.name, self.version, self.has_description? ? " - " + self.description : ""], "\n", 4, true)
          show_synopsis(console)
        end

        # Prints a synopsis about the application.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_synopsis(console)
          console.write("")
          console.write(self.i18n.help_synopsis)
          console.write(self.synopsis.present? ? self.synopsis : self.i18n.help_application_synopsis % [self.executable_name, self.has_commands? ? self.i18n.help_subcommand_invocation : ""], "\n", 4, true)
        end

        # Prints a help summary about the command.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_command_summary(console)
          console.write(self.i18n.help_synopsis)
          console.write(self.synopsis.present? ? self.synopsis : self.i18n.help_command_synopsis % [self.application.executable_name, self.full_name(nil, " "), self.has_commands? ? self.i18n.help_subsubcommand_invocation : ""], "\n", 4, true)
        end

        # Prints the description of the command.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_banner(console)
          console.write("")
          console.write(self.i18n.help_description)
          console.write(self.banner, "\n", 4, true)
        end

        # Prints information about the command's options.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_options(console)
          console.write("")
          console.write(self.is_application? ? self.i18n.help_global_options : self.i18n.help_options)

          # First of all, grab all options and construct labels
          lefts = show_help_options_build_labels

          console.with_indentation(4) do
            lefts.keys.sort.each do |head|
              show_help_option(console, lefts, head)
            end
          end
        end

        # Adjusts options names for printing.
        #
        # @return [Hash] The adjusted options for printing.
        def show_help_options_build_labels()
          self.options.values.inject({}) do |lefts, option|
            left = [option.complete_short, option.complete_long]
            left.collect!{|l| " " + option.meta } if option.requires_argument?
            lefts[left.join(", ")] = option.has_help? ? option.help : self.i18n.help_no_description
            lefts
          end
        end

        # Prints information about an option.
        #
        # @param console [Bovem::Console] The console object to use to print.
        # @param lefts [Hash] The list of adjusted options.
        # @param head [String] The option to print.
        def show_help_option(console, lefts, head)
          alignment = lefts.keys.collect(&:length).max
          help = lefts[head]
          console.write("%s - %s" % [head.ljust(alignment, " "), help], "\n", true, true)
        end

        # Prints information about the command's subcommands.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_commands(console)
          alignment = prepare_show_help_commands(console)

          console.with_indentation(4) do
            self.commands.keys.sort.each do |name|
              show_help_command(console, name, alignment)
            end
          end
        end

        # Starts printing information about the command's subcommands.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def prepare_show_help_commands(console)
          console.write("")
          console.write(self.is_application? ? self.i18n.help_commands : self.i18n.help_subcommands)
          self.commands.keys.collect(&:length).max
        end

        # Prints information about a command's subcommand.
        #
        # @param name [String] The name of command to print.
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_command(console, name, alignment)
          # Find the maximum lenght of the commands
          command = self.commands[name]
          console.write("%s - %s" % [name.ljust(alignment, " "), command.description.present? ? command.description : self.i18n.help_no_description], "\n", true, true)
        end
    end
  end

  # This class represent a command (action) for Mamertes.
  #
  # Every command has the execution block and a set of option. Optionally, it also has before and after hooks.
  #
  # @attribute name
  #   @return [String] The name of this command. At runtime you can invoke it using the minimum number of letters to uniquely distinguish it from others.
  # @attribute description
  #   @return [String] A very short description of what this command does.
  # @attribute banner
  #   @return [String] A long description of this command.
  # @attribute synopsis
  #   @return [String] A synopsis of the typical command line usage.
  # @attribute before
  #   @return [Proc] A hook to execute before the command's action. It is executed only if no subcommand is executed.
  # @attribute action
  #   @return [Proc] The action of this command. It is executed only if no subcommand is executed.
  # @attribute after
  #   @return [Proc] A hook to execute after the command's action. It is executed only if no subcommand is executed.
  # @attribute application
  #   @return [Application] The application this command belongs to.
  # @attribute parent
  #   @return [Command] The parent of this command.
  # @attribute [r] commands
  #   @return [Array] The subcommands associated to this command.
  # @attribute [r] options
  #   @return [Array] The options available for this command.
  # @attribute [r] arguments
  #   @return [Array] The arguments provided to this command.
  class Command
    attr_accessor :name
    attr_accessor :description
    attr_accessor :banner
    attr_accessor :synopsis
    attr_accessor :before
    attr_accessor :action
    attr_accessor :after
    attr_accessor :application
    attr_accessor :parent
    attr_reader :commands
    attr_reader :options
    attr_reader :arguments

    include Lazier::I18n
    include Mamertes::CommandMethods::Help

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
        [@parent ? @parent.full_name(nil, separator) : nil, !self.is_application? ? self.name : nil, suffix].compact.join(separator)
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

      options = {name: name.to_s, parent: self, application: self.application}.merge(!options.is_a?(::Hash) ? {} : options)
      raise Mamertes::Error.new(self, :duplicate_command, self.i18n.existing_command(self.full_name(name))) if @commands[name.to_s]

      create_command(name, options, &block)
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
          raise Mamertes::Error.new(self, :duplicate_option, self.i18n.existing_option_global(name))
        else
          raise Mamertes::Error.new(self, :duplicate_option, self.i18n.existing_option(name, self.full_name))
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
      setup_i18n(options)

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

      if subcommand.present? then # We have a subcommand to call
        self.commands[subcommand[:name]].execute(subcommand[:args])
      elsif self.action then # Run our action
        # Run the before hook
        self.before.call(self) if self.before

        # Run the action
        self.action.call(self) if self.action

        # Run the after hook
        self.after.call(self) if self.after
      else # Show the help
        self.show_help
      end
    end

    private
      # Setup the application localization.
      #
      # @param options [Hash] The setttings for this command.
      def setup_i18n(options)
        self.i18n_setup(:mamertes, ::File.absolute_path(::Pathname.new(::File.dirname(__FILE__)).to_s + "/../../locales/"))
        self.i18n = (options[:locale] || :en).ensure_string
      end

      # Creates a new command.
      #
      # @param name [String] The name of this command.
      # @param options [Hash] The setttings for this command.
      # @return [Command] The new command.
      def create_command(name, options, &block)
        command = ::Mamertes::Command.new(options, &block)
        command.option(:help, [self.i18n.help_option_short_form, self.i18n.help_option_long_form], help: self.i18n.help_message){|command, option| command.show_help }
        @commands[name.to_s] = command
        command
      end
  end
end