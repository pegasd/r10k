require 'r10k/hg/rev'
require 'r10k/hg/repository'

# A branch is the set of all changesets with the same branch name.
#
# @see http://mercurial.selenic.com/wiki/Branch
# @api private
class R10K::Hg::Branch < R10K::Hg::Rev

  # @!attribute [r] branch
  #   @return [String] The hg branch
  attr_reader :branch
  alias :rev :branch

  def initialize(branch, repository = nil)
    @branch = branch
    @repository = repository
  end

  # If we are tracking a branch, we should always try to pull a newer version
  # of that branch.
  def pull?
    true
  end
end
