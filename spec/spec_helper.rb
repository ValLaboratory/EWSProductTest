# -*- coding: utf-8 -*-

require 'rspec'
require 'rest-client'
require 'nokogiri'
require 'json'
require 'jsonpath'
require 'open-uri'
require 'yaml'
require 'net/http'
require 'date'
require 'pp'
require File.expand_path('shared_examples', File.dirname(__FILE__))


module EWSAppTest
	ENV = YAML.load( File.read( File.expand_path('../config/env.yaml', File.dirname(__FILE__)) ) )
  METHOD_WITH_DATE_TIME = YAML.load(File.read(File.expand_path('../config/method_with_date_time.yaml', File.dirname(__FILE__))))

	def _get_ews_url
		ENV['webservice']
	end

	def _get_ews_base_url
		webservice = ENV['webservice']
		version = ENV['version']
		"#{webservice}/#{version}"
	end

	def _get_key
		key = ENV['key']
		key
	end

	def _get(method, query, format='xml', closed=false)
		encoded_query = nil
		if query
			encoded_query = query.split('&').collect {|name_and_value| "#{URI.encode(name_and_value.split('=')[0])}=#{URI.encode(name_and_value.split('=')[1])}" }.join('&')
		end
		url = "#{_get_ews_base_url}/#{format}#{'/closed' if closed}#{method}?key=#{_get_key}"
		url += "&#{encoded_query}" if encoded_query
		begin
			RestClient.get url
		rescue =>e
			pp "Error URL: #{url}"
			return e.response if e.methods.include?(:response)
			raise e
		end
	end

	def get_xml(method, query, closed=false)
		_get(method, query, 'xml', closed)
	end

	def get_json(method, query, closed=false)
		_get(method, query, 'json', closed)
	end

	# rest_client を使わずにgetする
	# 例えば rest_client では bad URI になってしまうリクエストを送信したりすることが事ができる
	def get_naked(method_query)
		method = method_query.split('?')[0]
		query = method_query.split('?')[1]
		url = URI.parse("#{_get_ews_url}#{method}")
		begin
			if ENV['proxy']
				net_http = Net::HTTP::Proxy(ENV['proxy'], ENV['proxy_port'].to_i)
			else
				net_http = Net::HTTP
			end			
			res = net_http.start(url.host, url.port) {|http|
				path_query = url.path
				path_query += "?#{query}" if query
				http.get(path_query)
			}
			res
		rescue =>e
			return e.response if e.methods.include?(:response)
			raise e
		end
	end

	#
	# 複数のサブジェクトに対して一つのマッチャーを実行する
	# subject_hash は例えば {:xml=>xml_subject, :json=>json_subject } の用にする 
	#
	def it_multi_subject(text, subject_hash, matcher, *args, &block)
	  subject_hash.each{|key, subject|
	    it "#{text}(#{key.to_s})" do
	    	if matcher == :be_within
	    		delta = args[1]
	    		expected = args[0]
	    		expect(subject).to be_within(delta).of(expected)
	    	else
	      		expect(subject).to __send__(matcher, *args, &block)
	      	end
	    end
	  }
	end

	def get_course_point(query)
		doc = Nokogiri::XML( get_xml('/toolbox/course/point', query) )
		doc.xpath('//SerializeData/text()').to_s
	end

	def get_trainCode(date, stationName, arrivalStationName)
	    doc = Nokogiri::XML( get_xml('/train/timetable', "stationName=#{stationName}&date=#{date}") )
	    serviceSectionCode = doc.xpath("//ServiceSection[@arrival='#{arrivalStationName}']/@code")[0].text
	    doc = Nokogiri::XML( get_xml('/train/timetable', "serviceSectionCode=#{serviceSectionCode}&date=#{date}") )
	    doc.xpath('//Line[1]/@code').text
	end

	def get_train_DepAndArrTime(date, stationName, arrivalStationName)
	    doc = Nokogiri::XML( get_xml('/train/timetable', "stationName=#{stationName}&date=#{date}") )
	    serviceSectionCode = doc.xpath("//ServiceSection[@arrival='#{arrivalStationName}']/@code")[0].text
	    doc = Nokogiri::XML( get_xml('/train/timetable', "serviceSectionCode=#{serviceSectionCode}&date=#{date}") )
	    [doc.xpath('//Line[1]//DepartureState/Datetime')[0].text.to_s,  doc.xpath('//Line[1]//ArrivalState/Datetime')[-1].text.to_s]
	end


	def get_course_serial(query, course_num)
		doc = Nokogiri::XML( get_xml('/search/course/extreme', query) )
		doc.xpath("//Course[#{course_num}]/SerializeData/text()").to_s
	end

	def get_condition(query)
		doc = Nokogiri::XML( get_xml('/toolbox/course/condition', query) )
		doc.xpath('//Condition/text()').to_s
	end


	def easy_create_teiki(viaList)
		serializeData = get_course_serial("date=#{Time.now.strftime("%Y%m%d").to_s}&time=1000&viaList=#{viaList}&", 1)
		doc = Nokogiri::XML( get_xml("/course/create/teiki", "serializeData=#{serializeData}") )
		doc.xpath('//TeikiSerializeData/text()').to_s
	end

	def _hash_to_query(hash)
		return '' if !hash
		array = []
		hash.each do |key, value|
			array << "#{key}=#{value}"
		end
		array.join('&')
	end

	def get_query_string(query)
		if query.class.name == 'Hash'
			_hash_to_query(query)
		elsif query.class.name == 'String'
			query
		end
	end

  def log_file_path
    ENV['log_file_path']
  end

  def _complement_date_time(method_query, datetime)
    path, query = method_query.split('?')
    method = path.sub(/^\/v1\/[^\/]+/, '')
    data = METHOD_WITH_DATE_TIME[method]
    return method_query if data.nil?

    ['date', 'time'].each do |param|
      next if data[param].nil? or query.match(/(^|&)#{param}=/)

      need_params = Array(data['need_params'])
      if need_params.empty? or need_params.all{|p| query.include?("#{p}=") }
        case data['default']
        when 'today'
          query = "#{params}&#{kind}=#{datetime.strftime('%Y%m%d')}"
        when 'now'
          query = "#{params}&#{kind}=#{datetime.strftime('%H%M')}"
        end
      end
    end
    "#{path}?#{query}"
  end

  def _pickup_time_and_method_query(record)
    datetime, method_query = record.values_at(3, 6)
    datetime = DateTime.strptime(datetime, '[%d/%b/%Y:%H:%M:%S')
    method_query = _complement_date_time(method_query, datetime)
    return datetime.strftime('%d/%b/%Y:%H:%M:%S'), method_query
  end

  def make_record_data(record)
    record = record.split(/\s/)
    time, method_query = _pickup_time_and_method_query(record)
    {
      'time'         => time,
      'method_query' => method_query,
      'check_targets' => {
        'http_status' => record[8],
        'body_size' =>{ 
          'size'  => record[9].to_i,
          'range' => 10
        }
      }
    }
  end

  def serialize_data_version_error?(method_query, res)
    return false unless method_query.match(/(^|&)serializeData=/)
    error = Nokogiri::XML(res).at_xpath('/ResultSet/Error/Message/text()')
    return false if error.nil?
    error.text.include?('シリアライズデータは同一のengineVersion間でのみ利用できます。')
  end
end



Dir["./support/**/*.rb"].each do |f|
  require f
end

RSpec.configure do |config|
	config.extend EWSAppTest
end





