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
      array = array.ensure_array
      separator = separator.ensure_string
      last_separator = last_separator.ensure_string

      array = array.collect {|a| quote.present? ? "#{quote}#{a}#{quote}" : a.ensure_string }
      case array.length
        when 0 then ""
        when 1 then array[0]
        when 2 then
          array[0] + last_separator + array[1]
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
        if arg.index(separator) then
          tokens = arg.split(separator, 2)
          arg = tokens[0]
          args.insert(0, tokens[1])
        end

        matching = command.commands.keys.select {|c| c =~ /^(#{Regexp.quote(arg)})/ }.compact
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
          if forms[option.complete_short] || forms[option.complete_long] then
            raise ::Mamertes::Error.new(command, :ambiguous_form, "Options #{option.label} and #{forms[option.complete_short].label} have conflicting forms.")
          else
            forms[option.complete_short] = option.dup
            forms[option.complete_long] = option.dup
          end

          if option.action.present? then
            opts.on("-#{option.short}", "--#{option.long}") do |value|
              option.execute_action
            end
          elsif option.type == String then # String arguments
            opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}") do |value|
              option.set(value)
            end
          elsif option.type == Integer then # Integer arguments
            opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}") do |value|
              raise ::Mamertes::Error.new(option, :invalid_argument, "Option #{option.label} expects a valid integer as argument.") if !value.is_integer?
              option.set(value.to_integer)
            end
          elsif option.type == Float then # Floating point arguments
            opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}") do |value|
              raise ::Mamertes::Error.new(option, :invalid_argument, "Option #{option.label} expects a valid floating number as argument.") if !value.is_float?
              option.set(value.to_float)
            end
          elsif option.type == Array then # Array/List arguments
            opts.on("#{option.complete_short} #{option.meta || "ARG"}", "#{option.complete_long} #{option.meta || "ARG"}", Array) do |value|
              option.set(value.ensure_array)
            end
          else # Boolean (argument-less) type by default
            opts.on("-#{option.short}", "--#{option.long}") do |value|
              option.set(value.to_boolean)
            end
          end
        end
      end

      begin
        if command.options.present? then
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

          # Check if any required option is missing.
          command.options.each_pair  do |name, option|
            raise ::Mamertes::Error.new(option, :missing_option, "Required option #{option.label} is missing.") if option.required && !option.provided?
          end
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
  end
end