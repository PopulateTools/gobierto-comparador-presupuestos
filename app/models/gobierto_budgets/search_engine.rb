# frozen_string_literal: true

module GobiertoBudgets
  class SearchEngine
    def self.client
      @client ||= Elasticsearch::Client.new log: false, url: ENV.fetch("ELASTICSEARCH_URL", "http://localhost:9200")
    end

    # Position of a document in the ranking of the documents that match the query, sorted by field
    # in descending order, and the number of documents in the ranking. The position is nil when the
    # document is not in the ranking.
    def self.ranking_position(index:, query:, field:, id:, value:)
      response = client.search(
        index:,
        body: {
          query:,
          size: 0,
          track_total_hits: true,
          aggs: {
            ranked_document: { filter: { ids: { values: [id] } } },
            documents_ahead: { filter: { range: { field => { gt: value.to_f } } } }
          }
        }
      )
      aggregations = response["aggregations"]
      position = aggregations["documents_ahead"]["doc_count"] + 1 if aggregations["ranked_document"]["doc_count"].positive?

      [position, response["hits"]["total"]["value"]]
    end
  end
end
