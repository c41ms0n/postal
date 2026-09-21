# frozen_string_literal: true

require "uri"

module Postal
  module MessageDB
    #
    # A blob store holds the large binary contents of raw messages outside the
    # message database. Keeping them out of the database means the database
    # never has to accept or store very large values (which are bounded by
    # max_allowed_packet) and lets that storage be scaled and tuned
    # independently of the metadata.
    #
    # blob_store.url selects a backend by scheme: "inline" (the default, which
    # disables the store), "filesystem" (a sharded directory) or "s3" (an
    # S3-compatible bucket). The contract is deliberately content-agnostic: a
    # store is handed bytes and returns an opaque key which is persisted
    # alongside the message and used to retrieve the bytes later.
    #
    module BlobStore

      class << self

        #
        # Build the blob store described by the configuration, or nil when the
        # bodies should stay inline in the message database.
        #
        def build
          uri = URI.parse(Postal::Config.blob_store.url.to_s)
          case uri.scheme
          when nil, "", "inline"
            nil
          when "filesystem"
            Filesystem.new(uri.path, depth(uri))
          when "s3"
            S3.new(uri)
          else
            raise Postal::Error, "Unknown blob store scheme '#{uri.scheme}'"
          end
        end

        private

        def depth(uri)
          value = uri.query ? URI.decode_www_form(uri.query).to_h["depth"] : nil
          (value || 2).to_i
        end

      end

    end
  end
end
