# frozen_string_literal: true

require_relative './test_helper'

require 'shrine'
require 'shrine/plugins/configurable_storage'
require 'shrine/plugins/signature'
require 'shrine/storage/memory'

class ContentAddressableFileReadOnlyTest < Minitest::Test

  class MyUploader < Shrine
    plugin :signature
    plugin :content_addressable
    plugin :configurable_storage

    configurable_storage_name :foo
  end

  def setup
    Shrine::Plugins::ConfigurableStorage.configure do |config|
      config[:default] = {
        read_only: @read_only_store = Shrine::Storage::Memory.new,
        read_write: @read_write_store = Shrine::Storage::Memory.new
      }
    end

    ContentAddressableFile.register_storage(@read_write_store)
    ContentAddressableFile.register_read_only_storage(@read_only_store)
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

  def upload_io(key, io)
    MyUploader.new(key).upload(io)
  end

  def test_can_delete_from_non_readonly_storages
    content_addressable = nil

    [MyUploader.new(:read_only), MyUploader.new(:read_write)].each do |uploader|
      uploaded_file = uploader.upload(StringIO.new('test content'))
      content_addressable = ContentAddressableFile.new(uploaded_file.content_addressable)
      assert_resolved?(content_addressable)
    end

    assert_store_exists?(@read_write_store, content_addressable)
    assert_store_exists?(@read_only_store, content_addressable)

    content_addressable.delete

    refute_store_exists?(@read_write_store, content_addressable)
    assert_store_exists?(@read_only_store, content_addressable)
    assert_resolved?(content_addressable)
  end
end
