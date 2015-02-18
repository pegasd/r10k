require 'r10k/hg'
require 'r10k/environment'
require 'r10k/util/purgeable'
require 'r10k/util/core_ext/hash_ext'

# This class implements a source for Hg environments.
#
# A Hg source generates environments by locally caching the given Hg
# repository and enumerating the branches for the Hg repository. Branches
# are mapped to environments without modification.
class R10K::Source::Hg < R10K::Source::Base

  include R10K::Logging

  R10K::Source.register(:hg, self)

  # @!attribute [r] remote
  #   @return [String] The pathname or URI to the hg repository
  attr_reader :remote

  # @!attribute [r] cache
  #   @api private
  #   @return [R10K::Hg::Cache] The hg cache associated with this source
  attr_reader :cache

  # @!attribute [r] settings
  #   @return [Hash<Symbol, Object>] Additional settings that configure how
  #     the source should behave.
  attr_reader :settings

  # @!attribute [r] invalid_branches
  #   @return [String] How Hg branch names that cannot be cleanly mapped to
  #     Puppet environments will be handled.
  attr_reader :invalid_branches

  # Initialize the given source.
  #
  # @param name [String] The identifier for this source.
  # @param basedir [String] The base directory where the generated environments will be created.
  # @param options [Hash] An additional set of options for this source.
  #
  # @option options [Boolean] :prefix Whether to prefix the source name to the
  #   environment directory names. Defaults to false.
  # @option options [String] :remote The pathname or URI to the hg repository
  # @option options [Hash] :remote Additional settings that configure how the
  #   source should behave.
  def initialize(name, basedir, options = {})
    super

    @environments = []

    @remote           = options[:remote]
    @invalid_branches = (options[:invalid_branches] || 'correct_and_warn')

    @cache  = R10K::Hg::Cache.generate(@remote)
  end

  # Update the hg cache for this hg source to get the latest list of environments.
  #
  # @return [void]
  def preload!
    logger.debug "Determining current branches for Hg source #{@remote.inspect}"
    @cache.sync
  end

  # Load the hg remote and create environments for each branch. If the cache
  # has not been pulled, this will return an empty list.
  #
  # @return [Array<R10K::Environment::Git>]
  def environments
    if not @cache.cached?
      []
    elsif @environments.empty?
      @environments = generate_environments()
    else
      @environments
    end
  end

  def generate_environments
    envs = []
    branch_names.each do |bn|
      if bn.valid?
        envs << R10K::Environment::Hg.new(bn.name, @basedir, bn.dirname,
                                          {:remote => remote, :rev => bn.name})
      elsif bn.correct?
       logger.warn "Environment #{bn.name.inspect} contained non-word characters, correcting name to #{bn.dirname}"
        envs << R10K::Environment::Hg.new(bn.name, @basedir, bn.dirname,
                                       {:remote => remote, :rev => bn.name})
      elsif bn.validate?
       logger.error "Environment #{bn.name.inspect} contained non-word characters, ignoring it."
      end
    end

    envs
  end

  include R10K::Util::Purgeable

  def managed_directory
    @basedir
  end

  def current_contents
    dir = self.managed_directory
    glob_part = @prefix ? @name.to_s() + '_*' : '*'
    glob_exp = File.join(dir, glob_part)

    Dir.glob(glob_exp).map do |fname|
      File.basename fname
    end
  end

  # List all environments that should exist in the basedir for this source
  # @note This implements a required method for the Purgeable mixin
  # @return [Array<String>]
  def desired_contents
    environments.map {|env| env.dirname }
  end

  private

  def branch_names
    @cache.branches.map do |branch|
      BranchName.new(branch, {
        :prefix     => @prefix,
        :sourcename => @name,
        :invalid    => @invalid_branches,
      })
    end
  end

  # @api private
  class BranchName

    attr_reader :name

    INVALID_CHARACTERS = %r[\W]

    def initialize(name, opts)
      @name = name
      @opts = opts

      @prefix = opts[:prefix]
      @sourcename = opts[:sourcename]
      @invalid = opts[:invalid]

      case @invalid
      when 'correct_and_warn'
        @validate = true
        @correct  = true
      when 'correct'
        @validate = false
        @correct  = true
      when 'error'
        @validate = true
        @correct  = false
      when NilClass
        @validate = opts[:validate]
        @correct = opts[:correct]
      end
    end

    def correct?; @correct end
    def validate?; @validate end

    def valid?
      if @validate
        ! @name.match(INVALID_CHARACTERS)
      else
        true
      end
    end

    def dirname
      dir = @name.dup

      if @prefix
        dir = "#{@sourcename}_#{dir}"
      end

      if @correct
        dir.gsub!(INVALID_CHARACTERS, '_')
      end

      dir
    end

  end
end
