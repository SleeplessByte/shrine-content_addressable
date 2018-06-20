# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'shrine/plugins/content_addressable'
require 'content_addressable_file'

require 'minitest/autorun'
