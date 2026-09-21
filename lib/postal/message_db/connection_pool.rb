# frozen_string_literal: true

module Postal
  module MessageDB
    class ConnectionPool

      attr_reader :connections

      def initialize
        @connections = []
        @lock = Mutex.new
      end

      def use
        retried = false
        do_not_checkin = false
        begin
          connection = checkout

          yield connection
        rescue dialect.error_class => e
          if e.message =~ /(lost connection|gone away|not connected)/i
            # If the connection has failed for a connectivity reason
            # we won't add it back in to the pool so that it'll reconnect
            # next time.
            do_not_checkin = true

            # If we haven't retried yet, we'll retry the block once more.
            if retried == false
              retried = true
              retry
            end
          end

          raise
        ensure
          checkin(connection) unless do_not_checkin
        end
      end

      private

      #
      # The dialect for the configured adapter. Used for driver-specific
      # connection handling and error detection.
      #
      def dialect
        @dialect ||= Dialects::Registry.for(Postal::Config.message_db.adapter)
      end

      def checkout
        @lock.synchronize do
          return @connections.pop unless @connections.empty?
        end

        add_new_connection
        checkout
      end

      def checkin(connection)
        @lock.synchronize do
          @connections << connection
        end
      end

      def add_new_connection
        @lock.synchronize do
          @connections << establish_connection
        end
      end

      def establish_connection
        Dialects::Registry.for(Postal::Config.message_db.adapter).connect(Postal::Config.message_db)
      end

    end
  end
end
