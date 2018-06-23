# frozen_string_literal: true

require_relative '../../test_helper'

require 'shrine'
require 'shrine/plugins/configurable_storage'
require 'shrine/plugins/signature'
require 'shrine/storage/memory'

require 'digest'
require 'multihashes'

class Shrine
  module Plugins
    class ContentAddressableTest < Minitest::Test

      class MyUploader < Shrine
        plugin :configurable_storage
        plugin :signature
        plugin :content_addressable, hash: :sha256, prefix: '/ipfs'

        configurable_storage_name :default
      end

      class LegacyUploader < Shrine
        plugin :configurable_storage
        plugin :signature
        plugin :content_addressable, hash: :md5, prefix: '/bucket'

        configurable_storage_name :default
      end

      def setup
        Shrine::Plugins::ConfigurableStorage.configure do |config|
          config[:default] = {
            cache: Shrine::Storage::Memory.new
          }
        end
      end

      def test_location_is_content_addressable
        content = 'My content to address'

        cache_uploader = MyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))
        assert_equal '/ipfs/12205c7d1fdd9f6f9ad9ef3126ecdb71558b1ede29b0f606' \
                     '4c2eeb01616394ffb244',
                     cached_file.id
      end

      def test_content_address_is_multihash
        content = 'My content to address'

        cache_uploader = MyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))
        hash = cached_file.id.rpartition('/').last

        decoded = Multihashes.decode [hash].pack('H*')
        assert_equal 'sha2-256', decoded[:hash_function]
        assert_equal Digest(:SHA256).digest(content), decoded[:digest]
      end

      def test_hash_function_is_configurable
        content = 'My content to address'

        cache_uploader = LegacyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))

        assert_equal '/bucket/d5100777f94b4cf1c5fa677ca69639ac6c72',
                     cached_file.id
      end

      def test_is_a_content_addressable_file_like
        content = 'My content to address'

        cache_uploader = MyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))
        assert_equal 'sha2-256', cached_file.digest_hash_function
        assert_equal Digest(:SHA256).digest(content), cached_file.digest
      end

      def test_passes_content_addressable_equality
        content = 'My content to address'
        cache_uploader = MyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))

        assert_equal ContentAddressableFile.new(cached_file.content_addressable), cached_file
      end

      def test_to_content_addressable
        content = 'My content to address'
        cache_uploader = MyUploader.new(:cache)
        cached_file = cache_uploader.upload(StringIO.new(content))

        content_addressable_file = cached_file.to_content_addressable!
        assert_kind_of(ContentAddressableFile, content_addressable_file)
        assert_equal cached_file, content_addressable_file
        assert_equal cached_file.content_addressable, content_addressable_file.content_addressable

        # Test deletion propagation
        assert cached_file.storage.exists?(cached_file.id)
        assert content_addressable_file.exists?, 'Expected storage to be registered implicitly'

        content_addressable_file.delete

        refute content_addressable_file.exists?
        refute cached_file.storage.exists?(cached_file.id)
      end
    end
  end
end
