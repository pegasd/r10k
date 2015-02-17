require 'r10k/errors'

module R10K
  module HG

    class HGError < R10K::Error; end

    class UnresolvableRevError < HGError

      attr_reader :rev
      attr_reader :dir

      def initialize(mesg, options = {})
        super
        @rev = @options[:rev]
        @dir = @options[:dir]
      end

      def message
        msg = super
        if @dir
          msg << " at #{@dir}"
        end
        msg
      end
    end
  end
end
