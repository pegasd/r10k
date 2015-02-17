require 'r10k/hg'
require 'r10k/util/subprocess'

# Define an abstract base class for hg repositories.
class R10K::HG::Repository

  # @!attribute [r] remote
  #   Either the pathname of a local repository or the URI of a remote
  #   repository
  #   @return [String] The pathname or URI to the hg repository
  attr_reader :remote

  # @!attribute [r] basedir
  #   @return [String] The directory containing the repository
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The name of the directory
  attr_reader :dirname

  # Resolve a revision to a hg commit. The given revision can be a changeset,
  # tag, or a local or remote branch
  #
  # @param [String] rev
  #
  # @return [String] The dereferenced hash of `rev`
  def resolve_rev(rev)
    output = hg ['id', '-r', rev, '--debug'], :raise_on_fail => false

    if output.success?
      cset_id, _, name = output.stdout.lines.first.partition(/\s+/)
      cset_id
    else
      raise R10K::HG::UnresolvableRevError.new("Could not resolve HG revision '#{rev}'",
                                               :rev => rev, :dir => basedir)
    end
  end

  # @return [Hash<String, String>] A hash of remote names and URIs
  # @api private
  def remotes
    output = hg ['path']

    ret = {}
    output.stdout.each_line do |line|
      name, _, url = line.partition(/\s+\=\s+/)
      ret[name] = url
    end

    ret
  end

  def tags
    return list('tags')
  end

  def branches
    return list('branches')
  end

  private

  def list(command)
    entries = []
    output = hg([command]).stdout
    output.each_line { |line| entries << line.split[0] }
    entries
  end

  # Pull changes from the given hg repository
  #
  # @param remote [#to_s] The remote name to pull from
  def pull(remote = 'default')
    hg ['pull', remote]
  end

  # Wrap hg commands
  #
  # @param cmd [Array<String>] cmd The arguments for the hg prompt
  # @param opts [Hash] opts
  #
  # @option opts [String] :path
  # @option opts [String] :raise_on_fail
  #
  # @raise [R10K::ExecutionFailure] If the executed command exited with a
  #   nonzero exit code.
  #
  # @return [String] The hg command output
  def hg(cmd, opts = {})
    raise_on_fail = opts.fetch(:raise_on_fail, true)

    argv = %w{hg}

    if opts[:path]
      argv << "--cwd" << opts[:path]
    end

    argv.concat(cmd)

    subproc = R10K::Util::Subprocess.new(argv)
    subproc.raise_on_fail = raise_on_fail
    subproc.logger = self.logger

    result = subproc.execute

    result
  end
end
