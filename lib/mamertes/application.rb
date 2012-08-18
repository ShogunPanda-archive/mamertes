# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2012 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# Yet another command line manager.
module Mamertes
  # TODO: help command feature.

  # This exception is raised when something goes wrong.
  class Error < ArgumentError
    # The target of this error.
    attr_reader :target

    # The reason of failure.
    attr_reader :reason

    # A human readable message.
    attr_reader :message

    # Initializes a new error
    #
    # @param target [Object] The target of this error.
    # @param reason [Symbol] The reason of failure.
    # @param message [String] A human readable message.
    def initialize(target, reason, message)
      super(message)

      @target = target
      @reason = reason
      @message = message
    end
  end

  # This is the main class for a Mamertes application.
  #
  # Basically is the same of a command, but it adds support for application version.
  class Application < ::Mamertes::Command
    # The version of the application.
    attr_accessor :version

    # Creates a new application.
    #
    # @param options [Hash] The new options to initialize the application with.
    def initialize(options, &block)
      super(options, &block)
      help_option
    end

    # Reads and optionally sets the version of the application.
    #
    # @param value [NilClass|Object] The new version of the application.
    # @return [String] The version of the application.
    def version(value = nil)
      @version = value if !value.nil?
      @version
    end

    # Executes the application.
    #
    # @param args [Array] The command line to pass to the application. Defaults to `ARGV`.
    def execute(args = nil)
      super(args || ARGV)
    end

    # Adds an help command to the application.
    def help_option
      option :help, ["-h", "--help"], :help => "Shows this message." do |option, command|
        raise "USE BOVEM"
        buffer = PrettyPrint.new

        # Print the name
        buffer.format("[NAME]")
        buffer.nest(2) do
          buffer.format("%s %s - %s", command.name, command.version, command.description)
        end

        exit(0)
      end
    end
  end

  # Initializes a new Mamertes application.
  def self.App(options = {}, &block)
    raise Mamertes::Error.new(Mamertes::Application, :missing_block, "You have to provide a block to Mamertes::App!") if !block_given?

    options = {} if !options.is_a?(::Hash)
    options = {:name => "__APPLICATION__", :parent => nil, :application => nil}.merge(options)
    ::Mamertes::Application.new(options, &block).execute(options.delete(:__args__))
  end
end