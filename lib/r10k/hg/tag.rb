require 'r10k/hg/rev'
require 'r10k/hg/repository'

# A tag is a symbolic identifier for a changeset.
#
# @see http://mercurial.selenic.com/wiki/Tag
# @api private
class R10K::HG::Tag < R10K::HG::Rev

  # @!attribute [r] tag
  #   @return [String] The hg tag
  attr_reader :tag
  alias :rev :tag

  def initialize(tag, repository = nil)
    @tag = tag
    @repository = repository
  end

  def pull?
    # If we are tracking a tip, we should always try to pull a newer version.
    if tag == 'tip'
      true
    else
      ! resolvable?
    end
  end
end
