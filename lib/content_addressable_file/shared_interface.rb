# frozen_string_literal: true

require 'multihashes'

class ContentAddressableFile
  module SharedInterface
    def content_addressable
      @content_addressable ||= String(id).rpartition('/').last
    end

    # Tries to decode the multihash. This is a good check to see if the given id
    # is actually a content-addressable, but also easy to "fake", as the only way
    # to be certain that the id is a content addressable is actually getting the
    # file and hashing it again.
    def decode
      @decode ||= Multihashes.decode([content_addressable].pack('H*'))
    end

    # The #deocode digest as a byte array
    def digest
      decode[:digest]
    end

    # The #decode digest length
    def digest_length
      decode[:length]
    end

    # The #decode hash function
    def digest_hash_function
      decode[:hash_function]
    end

    # Returns true if the other File has the same id
    def ==(other)
      other.respond_to?(:digest) && content_addressable == other.content_addressable
    end
    alias eql? ==

    # Enables using File objects as hash keys.
    def hash
      [content_addressable].hash
    end
  end
end
