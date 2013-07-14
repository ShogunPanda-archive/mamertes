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
        console = is_application? ? console : application.console
        is_application? ? show_help_application_summary(console) : show_help_command_summary(console)
        show_help_banner(console) if has_banner?
        show_help_options(console) if has_options?
        show_help_commands(console) if has_commands?
        Kernel.exit(0)
      end

      private
        # Prints a help summary about the application.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_application_summary(console)
          # Application
          console.write(i18n.help_name)
          console.write("%s %s%s" % [name, version, has_description? ? " - " + description : ""], "\n", 4, true)
          show_synopsis(console)
        end

        # Prints a synopsis about the application.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_synopsis(console)
          console.write("")
          console.write(i18n.help_synopsis)
          console.write(synopsis.present? ? synopsis : i18n.help_application_synopsis % [executable_name, has_commands? ? i18n.help_subcommand_invocation : ""], "\n", 4, true)
        end

        # Prints a help summary about the command.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_command_summary(console)
          console.write(i18n.help_synopsis)
          console.write(synopsis.present? ? synopsis : i18n.help_command_synopsis % [application.executable_name, full_name(nil, " "), has_commands? ? i18n.help_subsubcommand_invocation : ""], "\n", 4, true)
        end

        # Prints the description of the command.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_banner(console)
          console.write("")
          console.write(i18n.help_description)
          console.write(banner, "\n", 4, true)
        end

        # Prints information about the command's options.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_options(console)
          console.write("")
          console.write(is_application? ? i18n.help_global_options : i18n.help_options)

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
        def show_help_options_build_labels
          options.values.inject({}) do |lefts, option|
            left = [option.complete_short, option.complete_long]
            left.collect!{|l| l + " " + option.meta } if option.requires_argument?
            lefts[left.join(", ")] = option.has_help? ? option.help : i18n.help_no_description
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
            commands.keys.sort.each do |name|
              show_help_command(console, name, alignment)
            end
          end
        end

        # Starts printing information about the command's subcommands.
        #
        # @param console [Bovem::Console] The console object to use to print.
        def prepare_show_help_commands(console)
          console.write("")
          console.write(is_application? ? i18n.help_commands : i18n.help_subcommands)
          commands.keys.collect(&:length).max
        end

        # Prints information about a command's subcommand.
        #
        # @param name [String] The name of command to print.
        # @param console [Bovem::Console] The console object to use to print.
        def show_help_command(console, name, alignment)
          # Find the maximum length of the commands
          command = commands[name]
          console.write("%s - %s" % [name.ljust(alignment, " "), command.description.present? ? command.description : i18n.help_no_description], "\n", true, true)
        end
    end

    # Methods to manage options and subcommands.
    module Children
      attr_reader :commands
      attr_reader :options

      # Adds a new subcommand to this command.
      #
      # @param name [String] The name of this command. Must be unique.
      # @param options [Hash] A set of options for this command.
      # @return [Command] The newly added command.
      def command(name, options = {}, &block)
        @commands ||= HashWithIndifferentAccess.new

        options = {name: name.to_s, parent: self, application: application}.merge(options.ensure_hash)
        raise Mamertes::Error.new(self, :duplicate_command, i18n.existing_command(full_name(name))) if @commands[name.to_s]

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
        @options ||= HashWithIndifferentAccess.new

        if @options[name] then
          if is_application? then
            raise Mamertes::Error.new(self, :duplicate_option, i18n.existing_option_global(name))
          else
            raise Mamertes::Error.new(self, :duplicate_option, i18n.existing_option(name, full_name))
          end
        end

        option = ::Mamertes::Option.new(name, forms, options, &action)
        option.parent = self
        @options[name] = option
        option
      end

      # Returns the list of subcommands of this command.
      #
      # @return [HashWithIndifferentAccess] The list of subcommands of this command.
      def commands
        @commands || HashWithIndifferentAccess.new
      end

      # Clear all subcommands of this commands.
      #
      # @return [Hash] The new (empty) list of subcommands of this command.
      def clear_commands
        @commands = {}
      end

      # Check if this command has subcommands.
      #
      # @return [Boolean] `true` if this command has subcommands, `false` otherwise.
      def has_commands?
        commands.length > 0
      end

      # Returns the list of options of this command.
      #
      # @return [HashWithIndifferentAccess] The list of options of this command.
      def options
        @options || HashWithIndifferentAccess.new
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
        options.length > 0
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

      # Get the list of the options of this command as an hash, where the keys are the options and the values are either
      # the user inputs or the defaults values.
      #
      # If the two prefixes collides, the command options take precedence over application options.
      #
      # @param unprovided [Boolean] If to include also options that were not provided by the user and that don't have any default value.
      # @param application [String] The prefix to use for including application's options. If falsy, only current command options will be included.
      # @param prefix [String] The prefix to add to the option of this command.
      # @param whitelist [Array] The list of options to include. By default all options are included.
      # @return [HashWithIndifferentAccess] The requested options.
      def get_options(unprovided = false, application = "application_", prefix = "", *whitelist)
        rv = HashWithIndifferentAccess.new
        rv.merge!(application.get_options(unprovided, nil, application, *whitelist)) if application && !is_application?
        rv.merge!(get_current_options(unprovided, prefix, whitelist))
        rv
      end

      private
        # Creates a new command.
        #
        # @param name [String] The name of this command.
        # @param options [Hash] The settings for this command.
        # @return [Command] The new command.
        def create_command(name, options, &block)
          command = ::Mamertes::Command.new(options, &block)
          command.option(:help, [i18n.help_option_short_form, i18n.help_option_long_form], help: i18n.help_message){|c, _| c.show_help }
          @commands[name.to_s] = command
          command
        end

        # Gets the list of the options of this command.
        # @param unprovided [Boolean] If to include also options that were not provided by the user and that don't have any default value.
        # @param prefix [String] The prefix to add to the option of this command.
        # @param whitelist [Array] The list of options to include. By default all options are included.
        # @return [HashWithIndifferentAccess] The requested options.
        def get_current_options(unprovided, prefix, whitelist)
          rv = HashWithIndifferentAccess.new
          whitelist = (whitelist.present? ? whitelist : options.keys).collect(&:to_s)

          options.each do |key, option|
            rv["#{prefix}#{key}"] = option.value if include_option?(whitelist, unprovided, key, option)
          end

          rv
        end

        # Checks if a option must be included in a hash.
        #
        # @param whitelist [Array] The list of options to include.
        # @param unprovided [Boolean] If to include also options that were not provided by the user and that don't have any default value.
        # @param key [String] The option name.
        # @param option [Option] The option to include.
        # @return [Boolean] Whether to include the option.
        def include_option?(whitelist, unprovided, key, option)
          whitelist.include?(key.to_s) && (option.provided? || option.has_default? || (unprovided && option.action.nil?))
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

    include Lazier::I18n
    include Mamertes::CommandMethods::Help
    include Mamertes::CommandMethods::Children

    # Creates a new command.
    #
    # @param options [Hash] The settings to initialize the command with.
    def initialize(options = {}, &block)
      setup_with(options)
      instance_eval(&block) if block_given?
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
      if is_application? then
        nil
      else
        [@parent ? @parent.full_name(nil, separator) : nil, !is_application? ? name : nil, suffix].compact.join(separator)
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

    # Returns the application this command belongs to.
    #
    # @return [Application] The application this command belongs to or `self`, if the command is an Application.
    def application
      is_application? ? self : @application
    end

    # Checks if the command is an application.
    #
    # @return [Boolean] `true` if command is an application, `false` otherwise.
    def is_application?
      is_a?(Mamertes::Application)
    end

    # Check if this command has a description.
    #
    # @return [Boolean] `true` if this command has a description, `false` otherwise.
    def has_description?
      description.present?
    end

    # Check if this command has a banner.
    #
    # @return [Boolean] `true` if this command has a banner, `false` otherwise.
    def has_banner?
      banner.present?
    end

    # Setups the command.
    #
    # @param options [Hash] The settings for this command.
    # @return [Command] The command.
    def setup_with(options = {})
      options = {} if !options.is_a?(::Hash)
      setup_i18n(options)

      options.each_pair do |option, value|
        method = option.to_s

        if respond_to?(method) && self.method(method).arity != 0 then
          send(method, value)
        elsif respond_to?(method + "=") then
          send(method + "=", value)
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
        commands[subcommand[:name]].execute(subcommand[:args])
      elsif action then # Run our action
        # Run the before hook
        before.call(self) if before

        # Run the action
        action.call(self) if action

        # Run the after hook
        after.call(self) if after
      else # Show the help
        show_help
      end
    end

    private
      # Setup the application localization.
      #
      # @param options [Hash] The settings for this command.
      def setup_i18n(options)
        i18n_setup(:mamertes, ::File.absolute_path(::Pathname.new(::File.dirname(__FILE__)).to_s + "/../../locales/"))
        self.i18n = (options[:locale]).ensure_string
      end
  end
end