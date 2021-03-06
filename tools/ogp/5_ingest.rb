#!/usr/bin/env ruby

require 'json'
require 'rsolr'


class IngestOgp
  def initialize(collection, url, skip = 0)
    @skip = skip
    raise ArgumentError, 'Collection not defined' unless collection.is_a? String
    @solr = RSolr.connect(:url => (url + '/' + collection))
    yield self
    close
  end
  
  def ingest(fn)
    puts "Ingesting #{fn}"
    json = JSON::parse(File.read(fn))
    n = 0
    json.each do |doc|
      next unless doc.is_a? Hash and not doc.empty?
      doc.delete('_version_')
      doc.delete('timestamp')
      putc "."
      begin
        @solr.add doc      
      rescue Exception => e
        puts e
      end unless n < @skip
      
      n += 1
      if n % 100 == 0
        @solr.commit 
        puts "\ncommit 100 records, #{n} total\n"
      end
    end
    puts "\n#{n} records\n"
    @solr.commit
  end
  
  def close
    @solr.commit
    #@solr.optimize
    @solr = nil
  end
  
end


# __MAIN__
IngestOgp.new(ARGV[0], (ARGV[1].nil?? 'http://localhost:8080/solr' : ARGV[1]), ARGV[2].nil?? 0 : ARGV[2].to_i) do |ogp|
  Dir.glob("transformed*.json") do |fn|
    ogp.ingest(fn)
  end
end
