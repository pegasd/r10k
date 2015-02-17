require 'r10k/hg'
require 'r10k/hg/repository'

# rev: A 40-byte hex representation of a SHA1 or a name that denotes a
# particular object.
#
# @see http://mercurial.selenic.com/wiki/CategoryGlossary
# @api private
class R10K::HG::Rev

  # @!attribute [r] rev
  #   @return [String] The hg revision
  attr_reader :rev

  # @!attribute [rw] repository
  #   @return [R10K::HG::Repository] A hg repository that can be used to
  #     resolve the hg revision to a changeset.
  attr_accessor :repository

  def initialize(rev, repository = nil)
    @rev = rev
    @repository = repository
  end

  # Can we locate the commit in the related repository?
  def resolvable?
    sha1
    true
  rescue R10K::HG::UnresolvableRevError
    false
  end

  # Should we try to fetch this revision?
  #
  # Since we don't know the type of this revision, we have to assume that it
  # might be a tag or a branch and always update accordingly.
  def fetch?
    true
  end

  def sha1
    if @repository.nil?
      raise ArgumentError, "Cannot resolve #{self.inspect}: no associated HG repository"
    else
      @repository.resolve_rev(rev)
    end
  end

  def ==(other)
    other.is_a?(R10K::HG::Rev) && other.sha1 == self.sha1
  rescue ArgumentError, R10K::HG::UnresolvableRevError
    false
  end

  def to_s
    rev
  end

  def inspect
    "#<#{self.class}: #{to_s}>"
  end
end
