# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # List of valid option types. Values are the default values for that type.
  OPTION_TYPES = {String => "", Integer => 0, Float => 0.0, Array => []}
  OPTION_TYPES.default = false

  # This class represents an option for a command.
  class Option
    # The name of the option.
    attr_accessor :name

    # The short form (i.e.: -h) for the option.
    attr_accessor :short

    # The long form (i.e.: --help) for the option.
    attr_accessor :long

    # The type of the option.
    attr_accessor :type

    # If the option is required.
    attr_accessor :required

    # The default value of the option.
    attr_accessor :default

    # The META argument for the option, used only when showing the help.
    attr_accessor :meta

    # An help message for this option.
    attr_accessor :help

    # The current value of this option.
    attr_accessor :value

    # The action associated to this option.
    attr_accessor :action

    # A constraint for valid values. Can be an Array or a Regexp.
    attr_accessor :validator

    # The parent of this command.
    attr_accessor :parent

    # Creates a new option.
    #
    # @param name [String] The name of the option. Must be unique.
    # @param forms [Array] An array of short and long forms for this option.
    # @param options [Hash] A set of options for this option.
    # @param action [Proc] The action of the option.
    def initialize(name, forms = [], options = {}, &action)
      name = name.to_s
      forms = forms.ensure_array
      options = {} if !options.is_a?(::Hash)

      # Set values
      self.name = name
      self.short = forms.length > 0 ? forms[0] : name[0, 1]
      self.long = forms.length == 2 ? forms[1] : name
      @provided = false

      # Set options
      options.each_pair do |option, value|
        self.send(option.to_s + "=", value) if self.respond_to?(option.to_s + "=")
      end

      # Associate action
      @action = action if action.present? && action.respond_to?(:call) && action.try(:arity) == 2
    end

    # Sets the short form of the option.
    #
    # @param value [String] The short form of the option.
    def short=(value)
      # Clean value
      mo = value.to_s.match(/^-{0,2}([a-z0-9])(.*)$/i)
      final_value = mo[1]

      @short = final_value if final_value.present?
    end

    # Sets the long form of the option.
    #
    # @param value [String] The short form of the option.
    def long=(value)
      # Clean value
      mo = value.to_s.match(/^-{0,2}(.+)$/)
      final_value = mo[1]

      @long = final_value if final_value.present?
    end

    # Sets the long form of the option. Can be a Object, an Array or a Regexp.
    #
    # @param value [String] The validator of the option.
    def validator=(value)
      # Clean value
      value = value.ensure_string if value.nil?
      value = value.ensure_array if !value.is_a?(Regexp)

      @validator = value
    end

    # Returns the short form with dash prepended.
    #
    # @return [String] The short form with dash prepended or `nil`, if the option has no short form.
    def complete_short
      self.short.present? ? "-#{self.short}" : nil
    end

    # Returns the long form with dash prepended.
    #
    # @return [String] The short form with dash prepended or `nil`, if the option has no long form.
    def complete_long
      self.long.present? ? "--#{self.long}" : nil
    end

    # Returns a label for this option, combining short and long forms.
    #
    # @return [String] A label for this option.
    def label
      [self.complete_short,self.complete_long].compact.join("/")
    end

    # Sets the value of the option and also make sure that it is validated.
    #
    # @param value [Object] The new value of the option.
    # @param raise_error [Boolean] If raise an ArgumentError in case of validation errors.
    # @return [Boolean] `true` if operation succeeded, `false` otherwise.
    def set(value, raise_error = true)
      vs = @validator.present? ? (@validator.is_a?(Array) ? :array : :regexp) : false # Check we have a validator
      rv = vs ? @validator.send(vs == :array ? "include?" : "match", value) : true

      if rv then
        @value = value
        @provided = true
      elsif raise_error then # Validation failed
        if vs == :array then
          raise ::Mamertes::Error.new(self, :validation_failed, "Value of option #{self.label} must be one of these values: #{::Mamertes::Parser.smart_join(validator)}.")
        else
          raise ::Mamertes::Error.new(self, :validation_failed, "Value of option #{self.label} must be match the regular expression: #{@validator.inspect}.")
        end
      else
        false
      end
    end

    # Executes the action associated to this option.
    def execute_action
      if self.action.present? then
        @provided = true
        self.action.call(self.parent, self)
      end
    end

    # If the option was provided.
    #
    # @return [Boolean] `true` if the option was provided, false otherwise.
    def provided?
      @provided
    end

    # Get the current value for the option
    #
    # @return [Object] The current value of the option.
    def value
      self.provided? ? @value : ::Mamertes::Option::Types[@type]
    end
  end
end