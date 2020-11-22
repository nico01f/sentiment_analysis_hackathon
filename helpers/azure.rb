def perform_analysis(service, document, key = "AZURE_KEY_TEXT_ANALYSIS", endpoint = "https://URL_TEXT_ANALYSIS.cognitiveservices.azure.com/")
  require "net/https"
  require "uri"
  require "json"
  require "logger"
  log = Logger.new(STDOUT)

  path = "/text/analytics/v3.0/#{service}"

  endpoint = URI(endpoint + path)
  request = Net::HTTP::Post.new(URI(endpoint))
  request["Content-Type"] = "application/json"
  request["Ocp-Apim-Subscription-Key"] = key
  request.body = document.to_json
  begin
    log.info("Getting ML Text Analysis...")
    response = Net::HTTP.start(endpoint.host, endpoint.port, :use_ssl => endpoint.scheme == "https") do |http|
      http.request (request)
    end

    parameters = Hash.new
    parameters = {
      :req => request,
      :res => response,
    }
    return parameters
  rescue => exception
    log.error(exception)
  end
end

def perform_sentiment(document)
  parameters = perform_analysis("sentiment", document)
  data_analysis = JSON(parameters[:res].body)["documents"][0]

  analysis = Array.new
  analysis = [
    data_analysis["sentiment"],
    data_analysis["confidenceScores"]["positive"],
    data_analysis["confidenceScores"]["negative"],
    data_analysis["confidenceScores"]["positive"],
  ]

  return analysis
end

def perform_keys(document)
  keys = Array.new
  parameters = perform_analysis("keyPhrases", document)
  JSON(parameters[:res].body)["documents"][0]["keyPhrases"].each do |v|
    keys << v
  end
  return keys
end



# documents = { 'documents': [{ "id" => "0x74764", "language" => "es", "text" => "me siento mal por esta cosa que es excelente" }] }


# print perform_sentiment(documents)
