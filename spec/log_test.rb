# -*- coding: utf-8 -*-

require 'spec_helper'
require 'json'
require 'erb'


describe "ログからWebサービスURLテスト" do
  File.open(log_file_path) do |file|
    tested_method_query = {}
    file.each_line do |line|
      data = make_record_data(line)
      next if tested_method_query[data['method_query']]
      tested_method_query[data['method_query']] = true
      context data['time'], data['method_query'] do
        it_behaves_like 'URLをGETした結果を確認', data
      end
    end
  end
end
