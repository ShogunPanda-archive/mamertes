# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # The parser for the command line.
  class Parser
    # Joins an array using multiple separators.
    #
    # @param array [Array] The array to join.
    # @param separator [String] The separator to use for all but last join.
    # @param last_separator [String] The separator to use for the last join.
    # @param quote [String] If not nil, elements are quoted with that element.
    # @return [String] The joined array.
    def self.smart_join(array, separator = ", ", last_separator = " and ", quote = "\"")
      separator = separator.ensure_string
      last_separator = last_separator.ensure_string

      array = array.ensure_array.collect {|a| quote.present? ? "#{quote}#{a}#{quote}" : a.ensure_string }

      if array.length < 2 then
        array[0] || ""
      else
        array[0, array.length - 1].join(separator) + last_separator + array[-1]
      end
    end

    # Finds a command which corresponds to an argument.
    #
    # @param arg [String] The string to match.
    # @param command [Command] The command to search subcommand in.
    # @param args [String] The complet list of arguments passed.
    # @param separator [String] The separator for joined syntax commands.
    # @return [Hash|NilClass] An hash with `name` and `args` keys if a valid subcommand is found, `nil` otherwise.
    def self.find_command(arg, command, args, separator = ":")
      args = args.ensure_array.dup
      rv = nil

      if command.commands.present? then
        arg, args = adjust_command(arg, args, separator)

        matching = match_subcommands(arg, command)
        if matching.length == 1 # Found a command
          rv = {name: matching[0], args: args}
        elsif matching.length > 1 # Ambiguous match
          raise ::Mamertes::Error.new(command, :ambiguous_command, "Command shortcut \"#{arg}\" is ambiguous across commands #{::Mamertes::Parser.smart_join(matching)}. Please add some other characters.")
        end
      end

      rv
    end

    # Parses a command/application.
    #
    # @param command [Command] The command or application to parse.
    # @param args [Array] The arguments to parse.
    # @return [Hash|NilClass] An hash with `name` (of a subcommand to execute) and `args` keys if a valid subcommand is found, `nil` otherwise.
    def self.parse(command, args)
      rv = nil
      args = args.ensure_array.dup
      forms = {}

      parser = OptionParser.new do |opts|
        # Add every option
        command.options.each_pair do |name, option|
          # Check that the option is unique
          check_unique(command, forms, option)

          if option.action.present? then
            parse_action(opts, option)
          elsif option.type == String then # String arguments
            parse_string(opts, option)
          elsif option.type == Integer then # Integer arguments
            parse_number(opts, option, :is_integer?, :to_integer, "Option #{option.label} expects a valid integer as argument.")
          elsif option.type == Float then # Floating point arguments
            parse_number(opts, option, :is_float?, :to_float, "Option #{option.label} expects a valid floating number as argument.")
          elsif option.type == Array then # Array/List arguments
            parse_array(opts, option)
          else # Boolean (argument-less) type by default
            parse_boolean(opts, option)
          end
        end
      end

      begin
        if command.options.present? then
          rv = parse_options(parser, command, args)
          check_required_options(command)
        elsif args.present? then
          # Try to find a command into the first argument
          fc = ::Mamertes::Parser.find_command(args[0], command, args[1, args.length - 1])

          if fc.present? then
            rv = fc
          else
            args.each do |arg|
              command.argument(arg)
            end
          end
        end
      rescue OptionParser::MissingArgument => e
        option = forms[e.args.first]
        raise ::Mamertes::Error.new(option, :missing_argument, "Option #{option.label} expects an argument.")
      rescue OptionParser::InvalidOption => e
        raise ::Mamertes::Error.new(option, :invalid_option, "Invalid option #{e.args}.")
      rescue Exception => e
        raise e
      end

      rv
    end

    private
      # Adjust a command so that it only specify a single command.
      #
      # @param arg [String] The string to match.
      # @param args [String] The complet list of arguments passed.
      # @param separator [String] The separator for joined syntax commands.
      # @return [Array] Adjust command and arguments.
      def self.adjust_command(arg, args, separator)
        if arg.index(separator) then
          tokens = arg.split(separator, 2)
          arg = tokens[0]
          args.insert(0, tokens[1])
        end

        [arg, args]
      end

      # Match a string against a command's subcommands.
      #
      # @param arg [String] The string to match.
      # @param command [Command] The command to search subcommand in.
      # @return [Array] The matching subcommands.
      def self.match_subcommands(arg, command)
        command.commands.keys.select {|c| c =~ /^(#{Regexp.quote(arg)})/ }.compact
      end

      # Check if a option is unique.
      #
      # @param command [Command] The command or application to parse.
      # @param forms [Hash] The current forms.
      # @param option [Option] The option to set.
      def self.check_unique(command, forms, option)
        if forms[option.complete_short] || forms[option.complete_long] then
          raise ::Mamertes::Error.new(command, :ambiguous_form, "Options #{option.label} and #{forms[option.complete_short].label} have conflicting forms.")
        else
          forms[option.complete_short] = option.dup
          forms[option.complete_long] = option.dup
        end
      end

      # Parses an action option. A block must be provided to deal with the value.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      def self.parse_option(opts, option)
        opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}") do |value|
          yield(value)
        end
      end

      # Parses an action option.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      def self.parse_action(opts, option)
        opts.on("-#{option.short}", "--#{option.long}") do |value|
          option.execute_action
        end
      end

      # Parses a string option.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      def self.parse_string(opts, option)
        parse_option(opts, option) { |value| option.set(value) }
      end

      # Parses a number option.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      # @param check_method [Symbol] The method to execute to check option validity. Must return a boolean.
      # @param convert_method [Symbol] The method to execute to convert option.
      # @param invalid_message [String] The string to send in case of invalid arguments.
      def self.parse_number(opts, option, check_method, convert_method, invalid_message)
        parse_option(opts, option) do |value|
          raise ::Mamertes::Error.new(option, :invalid_argument, invalid_message) if !value.send(check_method)
          option.set(value.send(convert_method))
        end
      end

      # Parses an array option.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      def self.parse_array(opts, option)
        opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}", Array) do |value|
          option.set(value.ensure_array)
        end
      end

      # Parses an action option.
      #
      # @param opts [Object] The current set options.
      # @param option [Option] The option to set.
      def self.parse_boolean(opts, option)
        opts.on("-#{option.short}", "--#{option.long}") do |value|
          option.set(value.to_boolean)
        end
      end

      # Parses options of a command.
      #
      # @param parser [OptionParser] The option parser.
      # @param command [Command] The command or application to parse.
      # @param args [Array] The arguments to parse.
      def self.parse_options(parser, command, args)
        rv = nil

        # Parse options
        parser.order!(args) do |arg|
          fc = ::Mamertes::Parser.find_command(arg, command, args)

          if fc.present? then
            rv = fc
            parser.terminate
          else
            command.argument(arg)
          end
        end

        rv
      end

      # Check if all options of a command are present.
      #
      # @param command [Command] The command or application to parse.
      def self.check_required_options(command)
        # Check if any required option is missing.
        command.options.each_pair  do |name, option|
          raise ::Mamertes::Error.new(option, :missing_option, "Required option #{option.label} is missing.") if option.required && !option.provided?
        end
      end
  end
end