# frozen_string_literal: true

module Postal
  module MessageDB
    module Dialects
      #
      # Resolves the dialect for a configured adapter.
      #
      # MySQL/MariaDB and PostgreSQL are wired up. The engines still under
      # evaluation (SQLite, RocksDB, FoundationDB, ClickHouse, DuckDB, ...) are
      # covered in doc/research/storage-engines.md; each one becomes selectable
      # here once its dialect and provisioning support land.
      #
      class Registry

        class UnsupportedAdapter < Postal::Error
        end

        # The adapter names which can be selected through message_db.adapter.
        ADAPTERS = %w[mariadb mysql postgresql sqlite].freeze

        class << self

          #
          # Return a dialect instance for the given adapter name. Raises
          # UnsupportedAdapter if the engine is unknown or not yet available.
          #
          def for(name)
            dialect = dialect_class(name)&.new
            if dialect.nil? || !dialect.available?
              raise UnsupportedAdapter, "The message database adapter '#{name}' is not supported. " \
                                        "Available adapters are: #{ADAPTERS.join(', ')}."
            end

            dialect
          end

          #
          # The adapter names which can be selected.
          #
          def names
            ADAPTERS
          end

          private

          #
          # Resolve the dialect class for an adapter name. Kept in a method so
          # the constant is looked up at call time and can be autoloaded.
          #
          def dialect_class(name)
            case name.to_s.downcase
            when "mysql", "mariadb" then MySQL
            when "postgres", "postgresql" then PostgreSQL
            when "sqlite" then SQLite
            end
          end

        end

      end
    end
  end
end
