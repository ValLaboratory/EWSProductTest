#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'kconv'

shared_examples 'XML形式のメソッドが機能している事を確認' do |_test_recode|
	subject_hash = {}
	begin
		query = get_query_string(_test_recode['query'])
		res   = get_xml( _test_recode['method'], query )
		subject_hash[:opend] = res.headers[:status].to_s
		if _test_recode['closed']
			res_closed = get_xml( _test_recode['method'], query , true)
			subject_hash[:closed] = res_closed.headers[:status].to_s
		end
		it_multi_subject 'http ステータスの確認', subject_hash, :eq, '200 OK'
		subject_hash = {}
		subject_hash[:opend] = Nokogiri::XML(res).xpath("//ResultSet").length
		if _test_recode['closed']
			subject_hash[:closed] = Nokogiri::XML(res_closed).xpath("//ResultSet").length
		end
		it_multi_subject 'ResultSet要素の有無', subject_hash, :eq, 1
	rescue =>e
		it "\n"+e.message+"\n"+e.backtrace.join("\n") do
			expect(false).to eq(true)
		end
	end
end


shared_examples 'JSON形式のメソッドが機能している事を確認' do |_test_recode|
	subject_hash = {}
	begin
		query = get_query_string(_test_recode['query'])
		res = get_json( _test_recode['method'], query )
		subject_hash[:opend] = res.headers[:status].to_s
		if _test_recode['closed']
			res_closed = get_json( _test_recode['method'], query , true)
			subject_hash[:closed] = res_closed.headers[:status].to_s
		end
		it_multi_subject 'http ステータスの確認', subject_hash, :eq, '200 OK'

		subject_hash = {}
		subject_hash[:opend] = JsonPath.new('$..ResultSet').on( JSON.parse(res) ).length
		if _test_recode['closed']
			subject_hash[:closed] = JsonPath.new('$..ResultSet').on( JSON.parse(res_closed) ).length
		end
		it_multi_subject 'ResultSet要素の有無', subject_hash, :eq, 1
	rescue =>e
		it "\n"+e.message+"\n"+e.backtrace.join("\n") do
			expect(false).to eq(true)
		end
	end
end

