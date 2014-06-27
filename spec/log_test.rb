# -*- coding: utf-8 -*-

require 'spec_helper'
require 'json'
require 'erb'

list = [
	{
		'method_query'=> '/v1/xml/station/light?key=AMP5FznGPXeT6psm&name=\x9e\xd6\x83\x96\x89\xaa&type=train',
		'check_targets'=> {
			'http_status'=>'200',
			'body_size'=>{ 
				'size'=>117,
				'range'=>10
			}
		}
	},
	{
		'method_query'=> '/v1/xml/corporation?key=wC4SR9ETBhBcJ3Bv&code=1',
		'check_targets'=> {
			'http_status'=>'200',
			'body_size'=>{
				'size'=>200,
				'range'=>10
			}
		}
	}
]



describe "ログからWebサービスURLテスト" do
	test_list = list
	test_list.each do |test_record|
		describe "#{test_record['method_query']}" do
			it_behaves_like 'URLをGETした結果を確認', test_record
		end
	end
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
