require_relative "helpers/middleware"
require "logger"

log = Logger.new(STDOUT)

loop do
    sleep 1
    
    begin
        log.info(" == Polling for new reviews")
        process_documents
    rescue => exception
        log.error(exception)
    end

end
