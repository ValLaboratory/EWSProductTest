# -*- coding: utf-8 -*-

require 'spec_helper'
require 'json'
require 'erb'

def pickup_key(method_query)
  query = method_query.split('?')[1]
  return nil if query.nil?
  key = nil
  query.split('&').each do |param|
    param = param.split('=')
    name = param.shift
    value = param.join('=')
    key = value if name == 'key' and !value.empty?
  end
  key
end

describe "ログからWebサービスURLテスト" do
  File.open(log_file_path) do |file|
    tested_method_query = {}
    checked_keys = {}
    file.each_line do |line|
      data = make_record_data(line)
      next if tested_method_query[data['method_query']]
      key = pickup_key(data['method_query'])
      checked_keys[key] = true unless key.nil?
      tested_method_query[data['method_query']] = true
      context data['time'], data['method_query'] do
        it_behaves_like 'URLをGETした結果を確認', data
      end
    end
    open(checked_keys_file_path, 'w') do |file|
      file.print checked_keys.keys.join("\n")
    end
  end
end
