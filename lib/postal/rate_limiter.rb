# frozen_string_literal: true

module Postal
  #
  # Rate limiting for Postal's public entry points: SMTP authentication, the
  # inbound SMTP listener, the API and web login.
  #
  # A limit is a count over a period against a namespaced key. The window starts
  # when the first event is counted and lasts for the period, so a limit of ten
  # failures per five minutes means ten failures from the first one, not ten
  # failures in whichever five-minute block the clock happens to be in.
  #
  # Counters are held in the process that counts them. That is exact for a
  # deployment with a single worker per service, which is the default; a
  # deployment running several workers would need a shared store, and the store
  # is therefore replaceable rather than hard-coded.
  #
  module RateLimiter

    class Error < StandardError; end

    #
    # The outcome of counting one event against a limit.
    #
    Result = Struct.new(:hits, :limit, :retry_after) do
      def allowed?
        hits <= limit
      end

      def exceeded?
        !allowed?
      end

      def remaining
        [limit - hits, 0].max
      end
    end

    # Returned when the limiter is switched off: nothing is counted and nothing
    # is refused.
    UNLIMITED = Result.new(0, Float::INFINITY, 0).freeze

    class << self

      #
      # Count one event against a key and report whether it is within its limit.
      # The result carries the number of seconds until the count resets, which is
      # what a caller quotes back to a client as a retry delay.
      #
      def check(key, limit:, period:)
        return UNLIMITED unless enabled?

        limit = limit.to_i
        period = period.to_i
        raise Error, "A rate limit needs a positive limit and period" if limit < 1 || period < 1

        store.increment(namespaced(key), limit: limit, period: period)
      end

      #
      # Count one event and report whether its limit has been exceeded. Callers
      # which only need a yes/no answer should use this.
      #
      def exceeded?(key, limit:, period:)
        check(key, limit: limit, period: period).exceeded?
      end

      #
      # Forget everything counted against a key. Used to clear a failure count
      # once the client has proved it is legitimate.
      #
      def clear(key)
        return unless enabled?

        store.clear(namespaced(key))
      end

      def enabled?
        Postal::Config.protection.enabled != false
      end

      def store
        @store ||= build_store
      end

      #
      # Replace the store. Any object which responds to #increment and #clear
      # with the signatures below can serve as one.
      #
      attr_writer :store

      #
      # Forget the memoised store so the next call rebuilds it from the current
      # configuration.
      #
      def reset!
        @store = nil
      end

      private

      def namespaced(key)
        prefix = Postal::Config.protection.prefix.to_s
        prefix.empty? ? key.to_s : "#{prefix}:#{key}"
      end

      def build_store
        url = Postal::Config.protection.counter_store.to_s
        case url.split(":", 2).first
        when "memory"
          Memory.new
        when "redis", "valkey"
          # redis-client speaks the Redis protocol, which is what Valkey and
          # other drop-in replacements implement, so the scheme names the
          # topology (shared store) rather than the client.
          Shared.new(url.sub(/\Avalkey:/, "redis:"))
        else
          raise Error, "protection.counter_store expects a memory://, redis:// or valkey:// URL, " \
                       "not #{url.inspect}"
        end
      end

    end

  end
end
