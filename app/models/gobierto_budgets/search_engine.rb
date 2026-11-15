# frozen_string_literal: true

module GobiertoBudgets
  class SearchEngine
    def self.client
      @client ||= Elasticsearch::Client.new log: false, url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200")
    end
  end
end
