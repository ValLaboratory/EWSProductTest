# -*- coding: utf-8 -*-

require 'spec_helper'
require 'json'
require 'erb'

describe "WebサービスURLテスト" do
	erb = ERB.new( File.read( "#{File.dirname(__FILE__)}/../template/url_list.erb" ) )
	test_list = JSON.parse( erb.result(binding) )
	method_list = test_list.collect{|elm| elm['method'] }
	test_list.each do |test_obj|
		query = get_query_string(test_obj['query'])
		describe "テスト「#{test_obj['name']}」 #{test_obj['method']}?#{query}" do
			describe 'xmlの結果' do
				it_behaves_like 'XML形式のメソッドが機能している事を確認', test_obj
			end
			describe 'jsonの結果' do
				it_behaves_like 'JSON形式のメソッドが機能している事を確認', test_obj
			end
		end
	end
end
