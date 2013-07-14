# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
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
  #
  # @attribute name
  #   @return [String] The name of this option.
  # @attribute short
  #   @return [String] The short form (i.e.: `-h`) for this option.
  # @attribute long
  #   @return [String] The long form (i.e.: `--help`) for this option.
  # @attribute type
  #   @return [Class] The type of this option.
  # @attribute required
  #   @return [Boolean] If this option is required.
  # @attribute default
  #   @return [Object] The default value of this option.
  # @attribute meta
  #   @return [String] The META argument for this option, used only when showing the help.
  # @attribute help
  #   @return [String] An help message for this option.
  # @attribute value
  #   @return [Object] The current value of this option.
  # @attribute action
  #   @return [Proc] The action associated to this option.
  # @attribute validator
  #   @return [Array|Regexp] or A constraint for valid values. Can be an Array of valid values or a Regexp.
  # @attribute parent
  #   @return [Command] The parent of this option.
  class Option
    attr_accessor :name
    attr_accessor :short
    attr_accessor :long
    attr_accessor :type
    attr_accessor :required
    attr_accessor :default
    attr_accessor :meta
    attr_accessor :help
    attr_accessor :value
    attr_accessor :action
    attr_accessor :validator
    attr_accessor :parent

    # Creates a new option.
    #
    # @param name [String] The name of this option. Must be unique.
    # @param forms [Array] An array of short and long forms for this option. Missing forms will be inferred by the name.
    # @param options [Hash] The settings for this option.
    # @param action [Proc] The action of this option.
    def initialize(name, forms = [], options = {}, &action)
      @name = name.ensure_string
      @provided = false
      setup_forms(forms)
      setup_options(options)
      setup_action(action)
    end

    # Sets the short form of this option.
    #
    # @param value [String] The short form of this option.
    def short=(value)
      value = @name[0, 1] if !value.present?

      # Clean value
      final_value = value.to_s.match(/^-{0,2}([a-z0-9])(.*)$/i)[1]

      @short = final_value if final_value.present?
    end

    # Sets the long form of this option.
    #
    # @param value [String] The short form of this option.
    def long=(value)
      value = @name if !value.present?

      # Clean value
      final_value = value.to_s.match(/^-{0,2}(.+)$/)[1]

      @long = final_value if final_value.present?
    end

    # Sets the long form of this option. Can be a Object, an Array or a Regexp.
    #
    # @param value [String] The validator of this option.
    def validator=(value)
      value = nil if value.blank? || (value.is_a?(Regexp) && value.source.blank?)
      value = value.ensure_array(nil, false, false, :ensure_string) if !value.nil? && !value.is_a?(Regexp)
      @validator = value
    end

    # Returns the short form with a dash prepended.
    #
    # @return [String] The short form with a dash prepended.
    def complete_short
      "-#{@short}"
    end

    # Returns the long form with two dashes prepended.
    #
    # @return [String] The short form with two dashes prepended.
    def complete_long
      "--#{@long}"
    end

    # Returns a label for this option, combining short and long forms.
    #
    # @return [String] A label for this option.
    def label
      [complete_short, complete_long].compact.join("/")
    end

    # Returns the meta argument for this option.
    #
    # @return [String|NilClass] Returns the current meta argument for this option (the default value is the option name uppercased) or `nil`, if this option doesn't require a meta argument.
    def meta
      requires_argument? ? (@meta.present? ? @meta : @name.upcase) : nil
    end

    # Get the current default value for this option.
    #
    # @return [Object] The default value for this option.
    def default
      @default || ::Mamertes::OPTION_TYPES[@type]
    end

    # Check if the current option has a default value.
    #
    # @return [Boolean] If the current option has a default value.
    def has_default?
      !@default.nil?
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
        handle_set_failure(vs)
      else
        false
      end
    end

    # Executes the action associated to this option.
    def execute_action
      if @action.present? then
        @provided = true
        @action.call(parent, self)
      end
    end

    # Checks if this option requires an argument.
    #
    # @return [Boolean] `true` if this option requires an argument, `false` otherwise.
    def requires_argument?
      [String, Integer, Float, Array].include?(@type) && @action.blank?
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
      @help.present?
    end

    # Get the current value for this option.
    #
    # @return [Object] The current value of this option.
    def value
      provided? ? @value : default
    end

    private
      # Setups the forms of the this option.
      #
      # @param forms [Array] An array of short and long forms for this option. Missing forms will be inferred by the name.
      def setup_forms(forms)
        self.short = forms.length > 0 ? forms[0] : @name[0, 1]
        self.long = forms.length == 2 ? forms[1] : @name
      end

      # Setups the settings of the this option.
      #
      # @param options [Hash] The settings for this option.
      def setup_options(options)
        (options.is_a?(::Hash) ? options : {}).each_pair do |option, value|
          send("#{option}=", value) if respond_to?("#{option}=")
        end
      end

      # Setups the action of the this option.
      #
      # @param action [Proc] The action of this option.
      def setup_action(action)
        @action = action if action.present? && action.respond_to?(:call) && action.try(:arity) == 2
      end

      # Handle failure in setting an option.
      #
      # @param vs [Symbol] The type of validator.
      def handle_set_failure(vs)
        if vs == :array then
          raise ::Mamertes::Error.new(self, :validation_failed, @parent.i18n.invalid_value(label, ::Mamertes::Parser.smart_join(@validator)))
        else
          raise ::Mamertes::Error.new(self, :validation_failed, @parent.i18n.invalid_for_regexp(label, @validator.inspect))
        end
      end
  end
end