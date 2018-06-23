# frozen_string_literal: true

require_relative './test_helper'

require 'digest'
require 'multihashes'

require 'shrine'
require 'shrine/plugins/configurable_storage'
require 'shrine/plugins/signature'
require 'shrine/storage/memory'

class ContentAddressableFileTest < Minitest::Test

  class MyUploader < Shrine
    plugin :signature
    plugin :content_addressable
    plugin :configurable_storage

    configurable_storage_name :foo
  end

  def setup
    Shrine::Plugins::ConfigurableStorage.configure do |config|
      config[:default] = {
        cache: @cache_store = Shrine::Storage::Memory.new,
        store: @store_store = Shrine::Storage::Memory.new
      }
    end

    ContentAddressableFile.register_storage(@store_store, @cache_store)
  end

  def teardown
    ContentAddressableFile.reset
  end

  def assert_store_exists?(store, id)
    id = id.respond_to?(:id) ? id.id : id
    assert store.exists?(id), format(
      'Expected %<store>s to have the content addressable %<id>s',
      store: store,
      id: id
    )
  end

  def refute_store_exists?(store, id)
    id = id.respond_to?(:id) ? id.id : id
    refute store.exists?(id), format(
      'Expected %<store>s not to have the content addressable %<id>s',
      store: store,
      id: id
    )
  end

  def assert_resolved?(content_addressable)
    assert content_addressable.exists?, format(
      'Expected the content addressable %<id>s to be resolved',
      id: content_addressable.id
    )
  end

  def refute_resolved?(content_addressable)
    refute content_addressable.exists?, format(
      'Expected the content addressable %<id>s not to be resolved',
      id: content_addressable.id
    )
  end

  def other_store(store)
    store == @store_store ? @cache_store : @store_store
  end

  def upload_io(key, io)
    MyUploader.new(key).upload(io)
  end

  def test_can_find_by_id
    uploader, store = [
      [MyUploader.new(:cache), @cache_store],
      [MyUploader.new(:store), @store_store]
    ].sample
    uploaded_file = uploader.upload(StringIO.new('test content'))

    content_addressable = ContentAddressableFile.new(uploaded_file.id)

    assert_store_exists?(store, content_addressable)
    assert_resolved?(content_addressable)
    assert_equal uploaded_file.url, content_addressable.url
    assert_equal store, content_addressable.storage

    refute_store_exists?(other_store(store), uploaded_file)
  end

  def test_can_delete_from_all_storages
    content_addressable = nil

    [MyUploader.new(:cache), MyUploader.new(:store)].each do |uploader|
      uploaded_file = uploader.upload(StringIO.new('test content'))
      content_addressable = ContentAddressableFile.new(uploaded_file.id)
      assert_resolved?(content_addressable)
    end

    assert_store_exists?(@cache_store, content_addressable)
    assert_store_exists?(@store_store, content_addressable)

    content_addressable.delete

    refute_resolved?(content_addressable)
    refute_store_exists?(@cache_store, content_addressable)
    refute_store_exists?(@store_store, content_addressable)
  end

  def test_registered_storage_order
    content_addressable = nil

    [MyUploader.new(:cache), MyUploader.new(:store)].each do |uploader|
      uploaded_file = uploader.upload(StringIO.new('test content'))
      content_addressable = ContentAddressableFile.new(uploaded_file.content_addressable)
      assert_resolved?(content_addressable)
    end

    assert_equal @store_store, content_addressable.storage
  end

  def test_open
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    assert_kind_of(StringIO, uploaded_file.open)
    uploaded_file.close

    uploaded_file.open do |io|
      assert_kind_of(StringIO, io)
    end
  ensure
    uploaded_file&.close
  end

  def test_io_read
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    io = uploaded_file.open
    assert_equal 'test content', uploaded_file.read
  ensure
    io&.close
  end

  def test_io_eof
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    io = uploaded_file.open

    refute uploaded_file.eof?, 'Expected not to be at eof'
    io.read
    assert uploaded_file.eof?, 'Expected to be at eof'
  ensure
    io&.close
  end

  def test_io_rewind
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    io = uploaded_file.open
    io.read
    uploaded_file.rewind
    assert_equal 'test content', io.read
  ensure
    io&.close
  end

  def test_io_close
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    io = uploaded_file.open
    uploaded_file.close
    assert io.closed?, 'Expected underlying io to be closed'
  ensure
    io&.close
  end

  def test_to_io
    uploaded_file = upload_io(:cache, StringIO.new('test content'))
    assert_kind_of(StringIO, uploaded_file.to_io)
    assert_equal 'test content', uploaded_file.to_io.read
  end

  def test_equality
    assert_equal ContentAddressableFile.new('foo'),
                 ContentAddressableFile.new('foo')
  end

  def test_decode_is_not_a_hash
    assert_raises do
      ContentAddressableFile.new('foo').decode
    end
  end

  def test_digest
    digest = Digest::MD5.digest('test content')
    file = ContentAddressableFile.new(Multihashes.encode(digest, 'md5').unpack('H*').first)
    assert_equal digest, file.digest
  end

  def test_digest_hash_function
    digest = Digest::MD5.digest('test content')
    file = ContentAddressableFile.new(Multihashes.encode(digest, 'md5').unpack('H*').first)
    assert_equal 'md5', file.digest_hash_function
  end
end
