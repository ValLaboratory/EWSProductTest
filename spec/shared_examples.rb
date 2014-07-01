#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'kconv'

shared_examples 'XML形式のメソッドが機能している事を確認' do |_test_recode|
	subject_hash = {}
	begin
		query = get_query_string(_test_recode['query'])
		res   = get_xml( _test_recode['method'], query )
		closed = _test_recode['closed']
		closed = true if closed == nil
		subject_hash[:opend] = res.headers[:status].to_s
		if closed
			res_closed = get_xml( _test_recode['method'], query , true)
			subject_hash[:closed] = res_closed.headers[:status].to_s
		end
		it_multi_subject 'http ステータスの確認', subject_hash, :eq, '200 OK'
		subject_hash = {}
		subject_hash[:opend] = Nokogiri::XML(res).xpath("//ResultSet").length
		if closed
			subject_hash[:closed] = Nokogiri::XML(res_closed).xpath("//ResultSet").length
		end
		it_multi_subject 'ResultSet要素の有無', subject_hash, :eq, 1
	rescue =>e
		it "\n"+e.message do
			expect(false).to eq(true), e.backtrace.join("\n")
		end
	end
end


shared_examples 'JSON形式のメソッドが機能している事を確認' do |_test_recode|
	subject_hash = {}
	begin
		query = get_query_string(_test_recode['query'])
		res = get_json( _test_recode['method'], query )
		subject_hash[:opend] = res.headers[:status].to_s
		closed = _test_recode['closed']
		closed = true if closed == nil
		if closed
			res_closed = get_json( _test_recode['method'], query , true)
			subject_hash[:closed] = res_closed.headers[:status].to_s
		end
		it_multi_subject 'http ステータスの確認', subject_hash, :eq, '200 OK'
		subject_hash = {}
		subject_hash[:opend] = JsonPath.new('$..ResultSet').on( JSON.parse(res) ).length
		if closed
			subject_hash[:closed] = JsonPath.new('$..ResultSet').on( JSON.parse(res_closed) ).length
		end
		it_multi_subject 'ResultSet要素の有無', subject_hash, :eq, 1
	rescue =>e
		it "\n"+e.message do
			expect(false).to eq(true), e.backtrace.join("\n")
		end
	end
end


#
# @args _test_recode 
# {
#     "method_query"=>"/toolbox/calendar/holidaylist?startDate=<%= Date.today.strftime('%Y%m%d') %>,
#     "check_targets"=> {
#	       "http_status"=>"200",
#	       "body_size"=>{"size”=>123456, "range"=>10}    #rangeは誤差 ％指定
#     }
# }
# @args http_status   チェックする status  string  '200' とか '400' を指定する。
#
shared_examples 'URLをGETした結果を確認' do |_test_recode|
	subject_hash = {}
	begin
		method_query = _test_recode['method_query']
		net_http_res = get_naked(method_query)
    
    if serialize_data_version_error?(method_query, net_http_res.body)
      it 'シリアライズデータのバージョン違いエラーは対象外。' do true end
    else
      if _test_recode['check_targets']['http_status']
        subject_hash = {}
        subject_hash[:opend] = net_http_res['status']
        it_multi_subject 'http ステータスの確認', subject_hash, :match, /#{_test_recode['check_targets']['status']}/
      end
      if _test_recode['check_targets']['body_size']
        subject_hash = {}
        # サイズの誤差の原因となる既知の文字列を取り除く
        response_body = net_http_res.body.sub(/\sstandalone='yes'/, '')
        response_body = response_body.gsub(/([{}:,\[\]"])\s+/, '\1') if method_query.match(/^\/v1\/json\//)
        subject_hash[:opend] = response_body.bytesize
        # 誤差許容範囲
        delta = (_test_recode['check_targets']['body_size']['size'] / 100) * _test_recode['check_targets']['body_size']['range']
        it_multi_subject "レスポンスのバイトサイズが誤差#{_test_recode['check_targets']['body_size']['range']}%に収まるか確認", subject_hash, :be_within, _test_recode['check_targets']['body_size']['size'], delta
      end
    end
	rescue =>e
		it "\n"+e.message do
			expect(false).to eq(true), e.message+"\n"+e.backtrace.join("\n")
		end
	end
end

