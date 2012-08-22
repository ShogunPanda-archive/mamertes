# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Mamertes
  # List of valid option types.
  #
  # Values are the default values for that type.
  #
  # For any unknown type, the default value is `false`, it means that any unknown type is managed as a Boolean value with no argument.
  OPTION_TYPES = {String => "", Integer => 0, Float => 0.0, Array => []}
  OPTION_TYPES.default = false

  # This class represents an option for a command.
  class Option
    # The name of this option.
    attr_accessor :name

    # The short form (i.e.: `-h`) for this option.
    attr_accessor :short

    # The long form (i.e.: `--help`) for this option.
    attr_accessor :long

    # The type of this option.
    attr_accessor :type

    # If this option is required.
    attr_accessor :required

    # The default value of this option.
    attr_accessor :default

    # The META argument for this option, used only when showing the help.
    attr_accessor :meta

    # An help message for this option.
    attr_accessor :help

    # The current value of this option.
    attr_accessor :value

    # The action associated to this option.
    attr_accessor :action

    # A constraint for valid values. Can be an Array of valid values or a Regexp.
    attr_accessor :validator

    # The parent of this option.
    attr_accessor :parent

    # Creates a new option.
    #
    # @param name [String] The name of this option. Must be unique.
    # @param forms [Array] An array of short and long forms for this option. Missing forms will be inferred by the name.
    # @param options [Hash] The settings for this option.
    # @param action [Proc] The action of this option.
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

    # Sets the short form of this option.
    #
    # @param value [String] The short form of this option.
    def short=(value)
      value = self.name[0, 1] if !value.present?

      # Clean value
      mo = value.to_s.match(/^-{0,2}([a-z0-9])(.*)$/i)
      final_value = mo[1]

      @short = final_value if final_value.present?
    end

    # Sets the long form of this option.
    #
    # @param value [String] The short form of this option.
    def long=(value)
      value = self.name if !value.present?

      # Clean value
      mo = value.to_s.match(/^-{0,2}(.+)$/)
      final_value = mo[1]

      @long = final_value if final_value.present?
    end

    # Sets the long form of this option. Can be a Object, an Array or a Regexp.
    #
    # @param value [String] The validator of this option.
    def validator=(value)
      value = nil if value.blank?
      value = nil if value.is_a?(Regexp) && value.source.blank?
      value = value.ensure_array.collect {|v| v.ensure_string} if !value.nil? && !value.is_a?(Regexp)
      @validator = value
    end

    # Returns the short form with a dash prepended.
    #
    # @return [String] The short form with a dash prepended.
    def complete_short
      "-#{self.short}"
    end

    # Returns the long form with two dashes prepended.
    #
    # @return [String] The short form with two dashes prepended.
    def complete_long
      "--#{self.long}"
    end

    # Returns a label for this option, combining short and long forms.
    #
    # @return [String] A label for this option.
    def label
      [self.complete_short,self.complete_long].compact.join("/")
    end

    # Returns the meta argument for this option.
    #
    # @return [String|NilClass] Returns the current meta argument for this option (the default value is the option name uppercased) or `nil`, if this option doesn't require a meta argument.
    def meta
      self.requires_argument? ? (@meta.present? ? @meta : @name.upcase) : nil
    end

    # Get the current default value for this option.
    # @return [Object] The default value for this option.
    def default
      @default || ::Mamertes::OPTION_TYPES[@type]
    end

    # Sets the value of this option and also make sure that it is validated.
    #
    # @param value [Object] The new value of this option.
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
          raise ::Mamertes::Error.new(self, :validation_failed, "Value of option #{self.label} must match the regular expression: #{@validator.inspect}.")
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

    # Checks if this option requires an argument.
    #
    # @return [Boolean] `true` if this option requires an argument, `false` otherwise.
    def requires_argument?
      [String, Integer, Float, Array].include?(self.type) && self.action.blank?
    end

    # If this option was provided.
    #
    # @return [Boolean] `true` if this option was provided, `false` otherwise.
    def provided?
      @provided
    end

    # Check if this command has a help.
    #
    # @return [Boolean] `true` if this command has a help, `false` otherwise.
    def has_help?
      self.help.present?
    end


    # Get the current value for this option.
    #
    # @return [Object] The current value of this option.
    def value
      self.provided? ? @value : self.default
    end
  end
end