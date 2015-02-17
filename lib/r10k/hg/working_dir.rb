require 'forwardable'
require 'inifile'
require 'r10k/hg'
require 'r10k/hg/cache'

# Implements hg working repository
class R10K::HG::WorkingDir < R10K::HG::Repository

  include R10K::Logging

  extend Forwardable

  # @!attribute [r] cache
  #   @return [R10K::HG::Cache] The cache backing this working directory
  attr_reader :cache

  # @!attribute [r] rev
  #   @return [R10K::HG::Rev] The hg revision to use check out in the given directory
  attr_reader :rev

  # @!attribute [r] remote
  #   @return [String] The actual remote used as an upstream for this module
  attr_reader :remote

  # Create a new hg working directory
  #
  # @param rev     [String, R10K::HG::Rev]
  # @param remote  [String]
  # @param basedir [String]
  # @param dirname [String]
  def initialize(rev, remote, basedir, dirname = nil)

    @remote  = remote
    @basedir = basedir
    @dirname = dirname || rev

    @path      = File.join(@basedir, @dirname)
    @hg_dir    = File.join(@path, '.hg')
    @hgrc_file = File.join(@hg_dir, 'hgrc')

    @cache = R10K::HG::Cache.generate(@remote)

    if rev.is_a? String
      @rev = R10K::HG::Rev.new(rev, self)
    else
      @rev = rev
      @rev.repository = self
    end
  end

  # Synchronize the local hg repository.
  def sync
    if not cloned?
      clone
    else
      update
    end
  end

  def update
    update_remotes if update_remotes?

    if rev_needs_pull?
      pull_from_cache
      checkout(@rev)
    elsif needs_checkout?
      checkout(@rev)
    end
  end

  # Determine if repo has been cloned into a specific dir
  #
  # @return [true, false] If the repo has already been cloned
  def cloned?
    File.directory? @hg_dir
  end
  alias :hg? :cloned?

  # Does a directory exist where we expect a working dir to be?
  # @return [true, false]
  def exist?
    File.directory? @path
  end

  # check out the given revision
  #
  # @param rev [R10K::HG::Rev] The hg revision to check out
  def checkout(rev)
    hg ["checkout", "--clean", @rev.sha1], :path => @path
  rescue => e
    raise R10K::HG::HGError.wrap(e, "Cannot check out HG revision '#{@rev}'")
  end

  # The currently checked out revision
  #
  # @return [R10K::HG::Changeset]
  def current
    R10K::HG::Changeset.new('', self)
  end

  def outdated?
    @rev.pull? or needs_checkout?
  end

  # Prefer remote changesets from the cache remote over the real remote
  def resolve_remote_rev(rev, remote = 'cache')
    super(rev, remote)
  end

  private

  # Do we need to pull additional changesets in order to resolve the
  # given revision?
  # @return [true, false]
  def rev_needs_pull?
    @rev.pull?
  end

  def pull_from_cache
    @cache.sync
    pull('cache')
  end

  # Perform a clone of a hg repository
  def clone
    @cache.sync
    hg ["clone", @cache.path, @path]
    update_remotes
    checkout(@rev)
  end

  # Does the expected revision match the actual revision?
  def needs_checkout?
    expected = rev.sha1
    actual   = resolve_rev('')

    !(expected == actual)
  end

  def update_remotes?
    real_remotes = remotes

    expected_default = @remote
    expected_cache  = @cache.path

    !(expected_default == real_remotes['default'] and
      expected_cache == real_remotes['cache'])
  end

  def update_remotes
    hgrc = IniFile.load(@hgrc_file)
    hgrc['paths'] = { 'default' => remote, 'cache' => @cache.path}
    hgrc.write
  end
end
