require 'r10k/module'
require 'r10k/hg'

class R10K::Module::Hg < R10K::Module::Base

  R10K::Module.register(self)

  def self.implement?(name, args)
    args.is_a? Hash and args.has_key?(:hg)
  rescue
    false
  end

  # @!attribute [r] working_dir
  #   @api private
  #   @return [R10K::Hg::WorkingDir]
  attr_reader :working_dir

  def initialize(title, dirname, args)
    super
    parse_options(@args)
    @working_dir = R10K::Hg::WorkingDir.new(@changeset, @remote, @dirname, @name)
  end

  def properties
    {
      :expected => @changeset,
      :actual   => (@working_dir.current.changeset rescue "(unresolvable)"),
      :type     => :hg,
    }
  end

  def sync
    case status
    when :absent
      install
    when :mismatched
      uninstall
      install
    when :outdated
      @working_dir.sync
    end
  end

  def status
    if not @working_dir.exist?
      return :absent
    elsif not @working_dir.hg?
      return :mismatched
    elsif not @remote == @working_dir.remote
      return :mismatched
    end

    if @working_dir.outdated?
      return :outdated
    end

    return :insync
  end

  private

  def install
    @working_dir.sync
  end

  def uninstall
    @path.rmtree
  end

  def parse_options(options)
    @remote = options.delete(:hg)

    if options[:branch]
      @changeset = R10K::Hg::Branch.new(options.delete(:branch))
    end

    if options[:tag]
      tag = options.delete(:tag)
      if tag == ':latest'
        tag = 'max(tagged())'
      end
      @changeset = R10K::Hg::Tag.new(tag)
    end

    if options[:changeset]
      @changeset = R10K::Hg::Changeset.new(options.delete(:changeset))
    end

    if options[:rev]
      @changeset = R10K::Hg::Rev.new(options.delete(:rev))
    end

    @changeset ||= R10K::Hg::Branch.new('default')

    unless options.empty?
      raise ArgumentError, "Unhandled options #{options.keys.inspect} specified for #{self.class}"
    end
  end
end
