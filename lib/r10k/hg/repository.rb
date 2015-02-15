require 'r10k/hg'
require 'r10k/util/subprocess'

# Define an abstract base class for hg repositories.
class R10K::HG::Repository

  # @!attribute [r] source
  #   Either the pathname of a local repository or the URI of a remote
  #   repository
  #   @return [String] The pathname or URI to the hg repository
  attr_reader :source

  # @!attribute [r] basedir
  #   @return [String] The directory containing the repository
  attr_reader :basedir

  # @!attribute [r] dirname
  #   @return [String] The name of the directory
  attr_reader :dirname

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
