class Cdx::Api::Service

  def setup
    yield config
  end

  def initialize_template(template_name)
    Cdx::Api::Elasticsearch::MappingTemplate.new(self).initialize_template(template_name)
  end

  def searchable_fields
    config.searchable_fields
  end

  def index_name_pattern
    config.index_name_pattern
  end

  def default_sort
    config.document_format.default_sort
  end

  def translate(response)
    format = config.document_format
    response.map { |test| format.translate_test(test) }
  end

  def search_elastic options
    unless options[:index].present?
      if index_name_pattern
        options[:index] = index_name_pattern
      else
        raise "You must define the index_name_pattern: Cdx::Api::Elasticsearch.setup { |config| config.index_name_pattern = ... }"
      end
    end

    client.search options
  end

  def client
    host = config.elasticsearch_url || "http://localhost:9200"
    if config.log
      ::Elasticsearch::Client.new log: true, trace: true, logger: Logger.new(STDOUT), host: host
    else
      ::Elasticsearch::Client.new log: false, host: host
    end
  end

  def elastic_index_pattern
    Settings.cdx_elastic_index_pattern
  end

  def config
    @config ||= Cdx::Api::Elasticsearch::Config.new
  end

end
