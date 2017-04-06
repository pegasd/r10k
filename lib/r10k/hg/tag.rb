require 'r10k/hg/rev'
require 'r10k/hg/repository'

LATEST_TAG = 'max(tagged())'

# A tag is a symbolic identifier for a changeset.
#
# @see http://mercurial.selenic.com/wiki/Tag
# @api private
class R10K::Hg::Tag < R10K::Hg::Rev

  # @!attribute [r] tag
  #   @return [String] The hg tag
  attr_reader :tag
  alias :rev :tag

  def initialize(tag, repository = nil)
    @tag = tag
    @repository = repository
  end

  def pull?
    # If we are tracking a float tag, we should always try to pull a
    # newer version.
    if tag == 'tip' || tag == LATEST_TAG
      true
    else
      ! resolvable?
    end
  end
end
