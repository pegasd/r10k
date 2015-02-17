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

  def resolve_tag(tag)
    return resolve('tags', tag)
  end

  def resolve_branch(branch)
    return resolve('branches', branch)
  end

  def resolve_changeset(changeset)
    return to_node_id(changeset)
  end

  def resolve_latest_tag()
    output = hg ['log', '-r', '"max(tagged())"', '--template',
                 '"{node}\\n"'], :raise_on_fail => false

    if output.success?
      output.stdout.lines.first
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

  def resolve(command, name)
    output = hg [command]

    output.stdout.each_line do |line|
      hg_name, _, changeset = line.partition(/\s+/)
      if hg_name == name
        _, id = parse_changeset(changeset)
        return to_node_id(id)
      end
    end
  end

  def parse_changeset(changeset)
    rev, _, id = changeset.partition(/\:/)
    rev, id
  end

  def to_node_id(id)
    output = hg ['log', '-r', id, '--template',
                 '"{node}\\n"'], :raise_on_fail => false

    if output.success?
      output.stdout.lines.first
    end
  end

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
