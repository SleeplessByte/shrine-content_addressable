# frozen_string_literal: true

require 'shrine'
require 'shrine/plugins/signature'

require 'multihashes'
require 'digest'

class Shrine
  module Plugins
    ##
    # plugin :signature
    # plugin :content_addressable
    #
    # This plugin uses the {Signature} plugin to turn the content into a content
    #   addressable, which simply means the digest of the content is now
    #   the location, and location the file by digest becomes possible.
    #
    # The results are wrapped in a multihash, so you may change your hashing
    #   method in production, whilst not losing access to the old hashes. This
    #   works by adding metadata to the hash of what function was used.
    #   https://github.com/multiformats/multihash
    #
    # @example Setup the plugin using sha256
    #
    #   plugin :content_addressable, hash: :sha256
    #   # /1220142711d38ca7a33c5218416f8ffcc64648ca4616a625b5e0a0ab3da1911d5d7a
    #
    # @example You can also prefix the final location, for example to make the
    #   location ready for IPFS
    #   https://ipfs.io/
    #
    #   plugin :content_addressable, hash: :sha256, prefix: 'ipfs'
    #   # /ipfs/1220142711d38ca7a33c5218416f8ffcc64648ca4616a625b5e0a0ab3da1911d5d7a
    #
    # @example Reading out the hash data
    #
    #   location = '/ipfs/1220142711d38ca7a33c5218416f8ffcc64648ca4616a625b5e0a0ab3da1911d5d7a'
    #   hash = location.rpartition('/').last
    #   out = Multihashes.decode [hash].pack('H*')
    #   # => {:code=>18, :hash_function=>"sha2-256", :length=>32, :digest=>"\x14'\x11\xD3\x8C\xA7\xA3<R\x18Ao\x8F\xFC\xC6FH\xCAF\x16\xA6%\xB5\xE0\xA0\xAB=\xA1\x 91\x1D]z"}
    #
    module ContentAddressable

      MULTIHASH_LOOKUP = {
        md5: 'md5',
        sha1: 'sha1',
        sha256: 'sha2-256',
        sha512: 'sha2-512'
      }.freeze

      def self.configure(uploader, opts = {})
        uploader.opts[:content_addressable_hash] = opts.fetch(:hash, uploader.opts[:content_addressable_hash])
        uploader.opts[:content_addressable_multihash] = opts.fetch(:multihash, uploader.opts[:content_addressable_multihash])
        uploader.opts[:content_addressable_prefix] = opts.fetch(:prefix, uploader.opts[:content_addressable_prefix])
      end

      module InstanceMethods
        def content_addressable_hash
          (opts[:content_addressable_hash] || 'sha256').to_sym
        end

        def content_addressable_multihash
          String(
            opts[:content_addressable_multihash] ||
            MULTIHASH_LOOKUP.fetch(content_addressable_hash)
          )
        end

        def content_addressable_hex(io)
          digest = calculate_signature(io, content_addressable_hash, format: :none)
          Multihashes.encode(digest, content_addressable_multihash)
                     .unpack('H*')
                     .first
        end

        def generate_location(io, _)
          [opts[:content_addressable_prefix], content_addressable_hex(io)].compact.join('/')
        end
      end
    end

    register_plugin(:content_addressable, ContentAddressable)
  end
end
