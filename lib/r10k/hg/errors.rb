require 'r10k/errors'

module R10K
  module HG

    class HGError < R10K::Error; end

    class UnresolvableChangesetError < HGError

      attr_reader :changeset
      attr_reader :hg_dir

      def initialize(mesg, options = {})
        super
        @changeset = @options[:changeset]
        @hg_dir    = @options[:hg_dir]
      end

      def message
        msg = super
        if @hg_dir
          msg << " at #{@hg_dir}"
        end
        msg
      end
    end
  end
end
