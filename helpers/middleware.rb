require_relative "azure"

def retrieve_reviews(limit = "6")
  require "uri"
  require "json"
  require "net/http"
  url = URI("http://rest.zone:58080/reviews/getNewReviews")
  http = Net::HTTP.new(url.host, url.port)
  request = Net::HTTP::Get.new(url)
  request["limit"] = limit
  response = http.request(request)

  return JSON.parse(response.read_body)["message"]["result"]
end

def update_review(id, sentiment, process = "ML")
  require "uri"
  require "net/http"
  require "logger"
  log = Logger.new(STDOUT)
  url = URI("http://rest.zone:58080/reviews/setReview")
  begin
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Post.new(url)
    request["id"] = id
    request["sentiment"] = sentiment
    request["process"] = process
    form_data = [["id", id.to_s], ["sentiment", sentiment.to_s]]
    request.set_form form_data, "multipart/form-data"
    response = http.request(request)
    return response.read_body
  rescue => exception
    log.error(exception)
  end
end

def process_documents
  require "logger"
  log = Logger.new(STDOUT)
  threads = []
  data = retrieve_reviews
  if data == "No results"
    sleep 5
    return
  end
  data.each_with_index do |k, v|
    threads << Thread.new(k, v) {
      id = data[v]["id"]
      review = data[v]["review"]
      if review.empty?
        empty_string = { "string" => "empty", "positive" => 0, "negative" => 0, "neutral" => 0 }
        update_review(data[v]["id"], empty_string)
      else
        documents = { 'documents': [{ "id" => id, "language" => data[v]["language"], "text" => review }] }
        log.info("Updating ML Text Analysis to product: #{data[v]["id"]}")
        begin
          sentiment_string = perform_sentiment(documents)
          update_review(data[v]["id"], sentiment_string)
        rescue => e
          log.error(e)
        end
      end
    }
  end
  threads.each { |aThread| aThread.join }
end
