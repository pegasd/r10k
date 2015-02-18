require 'r10k/logging'
require 'r10k/puppetfile'
require 'r10k/hg/working_dir'

# This class implements an environment based on a Hg branch.
class R10K::Environment::Hg < R10K::Environment::Base

  include R10K::Logging

  # @!attribute [r] remote
  #   @return [String] The pathname or URI to the hg repository
  attr_reader :remote

  # @!attribute [r] rev
  #   @return [String] The hg revision to use for this environment
  attr_reader :rev

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::Hg::WorkingDir] The hg working directory backing this environment
  attr_reader :working_dir

  # Initialize the given Hg environment.
  #
  # @param name [String] The unique name describing this environment.
  # @param basedir [String] The base directory where this environment will be created.
  # @param dirname [String] The directory name for this environment.
  # @param options [Hash] An additional set of options for this environment.
  #
  # @param options [String] :remote The pathname or URI to the hg repository
  # @param options [String] :rev The hg revision to use for this environment
  def initialize(name, basedir, dirname, options = {})
    super
    @remote = options[:remote]
    @rev    = options[:rev]

    @working_dir = R10K::Hg::WorkingDir.new(@rev, @remote, @basedir, @dirname)
  end

  # Clone or update the given Hg environment.
  #
  # If the environment is being created for the first time, it will
  # automatically update all modules to ensure that the environment is complete.
  #
  # @api public
  # @return [void]
  def sync
    @working_dir.sync
    @synced = true
  end

  def status
    if !@working_dir.exist?
      :absent
    elsif !@working_dir.hg?
      :mismatched
    elsif !(@remote == @working_dir.remote)
      :mismatched
    elsif !@synced
      :outdated
    else
      :insync
    end
  end

  # @deprecated
  # @api private
  def sync_modules
    modules.each do |mod|
      logger.debug "Deploying module #{mod.name}"
      mod.sync
    end
  end
end
