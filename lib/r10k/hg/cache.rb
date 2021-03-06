require 'r10k/hg'
require 'r10k/hg/repository'

require 'r10k/settings'
require 'r10k/registry'

# Mirror a hg repository for caching
#
# @see hg help clone
class R10K::Hg::Cache < R10K::Hg::Repository

  include R10K::Settings::Mixin

  def_setting_attr :cache_root, File.expand_path(ENV['HOME'] ? '~/.r10k/hg': '/root/.r10k/hg')

  # Lazily construct an instance cache for R10K::Hg::Cache objects
  # @api private
  def self.instance_cache
    @instance_cache ||= R10K::InstanceCache.new(self)
  end

  # Generate a new instance with the given remote or return an existing object
  # with the given remote. This should be used over R10K::Hg::Cache.new.
  #
  # @api public
  # @param remote [String] The hg remote to cache
  # @return [R10K::Hg::Cache] The requested cache object.
  def self.generate(remote)
    instance_cache.generate(remote)
  end

  include R10K::Logging

  # @param [String] remote
  # @param [String] cache_root
  def initialize(remote)
    @remote = remote

    @path = File.join(settings[:cache_root], sanitized_dirname)
  end

  def sync
    if not @synced
      sync!
      @synced = true
    end
  end

  def sync!
    if cached?
      pull
    else
      logger.debug "Creating new Hg cache for #{@remote.inspect}"

      # TODO extract this to an initialization step
      unless File.exist? settings[:cache_root]
        FileUtils.mkdir_p settings[:cache_root]
      end

      hg ['clone', @remote, path]
    end
  rescue R10K::Util::Subprocess::SubprocessError => e
    raise R10K::Hg::HgError.wrap(e, "Couldn't update Hg cache for #{@remote}")
  end

  # @return [true, false] If the repository has been locally cached
  def cached?
    File.exist? path
  end

  private

  # Reformat the remote name into something that can be used as a directory
  def sanitized_dirname
    @remote.gsub(/[^@\w\.-]/, '-')
  end
end
