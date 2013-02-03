# encoding: utf-8
#
# This file is part of the mamertes gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

# Yet another command line manager.
module Mamertes
  # This exception is raised when something goes wrong.
  #
  # @attribute [r] target
  #   @return [Object] The target of this error.
  # @attribute [r] reason
  #   @return [Symbol] The reason of failure.
  # @attribute [r] message
  #   @return [String] A human readable message.

class Error < ArgumentError
    attr_reader :target
    attr_reader :reason
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
  #
  # @attribute version
  #   @return [String] The version of the application.
  # @attribute shell
  #   @return [::Bovem::Shell] A shell helper.
  # @attribute console
  #   @return [::Bovem::Console] A console helper.
  # @attribute skip_commands
  #   @return [Boolean] If to skip commands run via {#run}.
  # @attribute show_commands
  #   @return [Boolean] If to show command lines run via {#run}.
  # @attribute output_commands
  #   @return [Boolean] If to show the output of the commands run via {#run}.
  class Application < ::Mamertes::Command
    attr_accessor :version
    attr_accessor :shell
    attr_accessor :console
    attr_accessor :skip_commands
    attr_accessor :show_commands
    attr_accessor :output_commands

    # Creates a new application.
    #
    # @param options [Hash] The settings to initialize the application with.
    def initialize(options = {}, &block)
      super(options, &block)

      @shell = ::Bovem::Shell.instance
      @console = @shell.console
      @skip_commands = false
      @show_commands = false
      @output_commands = false

      help_option
    end

    # Reads and optionally sets the version of this application.
    #
    # @param value [String|nil] The new version of this application.
    # @return [String|nil] The version of this application.
    def version(value = nil)
      @version = value.ensure_string if !value.nil?
      @version
    end

    # Executes this application.
    #
    # @param args [Array] The command line to pass to this application. Defaults to `ARGV`.
    def execute(args = nil)
      super(args || ARGV)
    end

    # Adds a help command and a help option to this application.
    def help_option
      command :help, description: "Shows a help about a command." do
        action { |command| application.command_help(command) }
      end

      option(:help, ["-h", "--help"], help: "Shows this message."){|application, option| application.show_help }
    end

    # The name of the current executable.
    #
    # @return [String] The name of the current executable.
    def executable_name
      $0
    end

    # Shows a help about a command.
    #
    # @param command [Command] The command to show help for.
    def command_help(command)
      args = command.arguments.collect {|c| c.split(":") }.flatten.collect(&:strip).select{|c| c.present? }
      command = self

      args.each do |arg|
        # Find the command across
        next_command = ::Mamertes::Parser.find_command(arg, command, [])

        if next_command then
          command = command.commands[next_command[:name]]
        else
          break
        end
      end

      command.show_help
    end

    # Runs a command into the shell.
    #
    # @param command [String] The string to run.
    # @param message [String] A message to show before running.
    # @param show_exit [Boolean] If show the exit status.
    # @param fatal [Boolean] If quit in case of fatal errors.
    # @return [Hash] An hash with `status` and `output` keys.
    def run(command, message = nil, show_exit = true, fatal = true)
      @shell.run(command, message, !@skip_commands, show_exit, @output_commands, @show_commands, fatal)
    end
  end

  # Initializes a new Mamertes application.
  #
  # In options, you can override the command line arguments with `:__args__`, and you can skip execution by specifying `run: false`.
  #
  # @see Command#setup_with
  #
  # @param options [Hash] The settings to initialize the application with.
  # @return [Application] The created application.
  def self.App(options = {}, &block)
    raise Mamertes::Error.new(Mamertes::Application, :missing_block, "You have to provide a block to Mamertes::App!") if !block_given?

    options = {} if !options.is_a?(::Hash)
    options = {name: "__APPLICATION__", parent: nil, application: nil}.merge(options)
    args = options.delete(:__args__)
    run = options.delete(:run)
    run = (!run.nil? ? run : true).to_boolean

    application = ::Mamertes::Application.new(options, &block)
    application.execute(args) if application && run
    application
  end
end