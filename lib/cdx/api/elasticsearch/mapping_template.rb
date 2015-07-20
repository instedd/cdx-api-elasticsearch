class Cdx::Api::Elasticsearch::MappingTemplate

  def initialize(api = Cdx::Api)
    @api = api
  end

  # put_template!
  # create_default!
  def initialize_template(template_name)
    @api.client.indices.put_template name: template_name, body: template
  end

  def template
    {
      template: @api.config.template_name_pattern,
      mappings: {
        test: mapping
      }
    }
  end

  def mapping
    {
      dynamic_templates: build_dynamic_templates,
      properties: build_properties_mapping
    }
  end

  def update_indices
    @api.client.indices.put_mapping({
      index: @api.config.template_name_pattern,
      body: mapping,
      type: 'test'
    })
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => ex
    nil
  end

  def build_dynamic_templates
    [
      {
        "*.admin_levels" => {
          path_match: "admin_level_*",
          mapping: { type: :string, index: :not_analyzed }
        }
      },
      {
        "custom_fields" => {
          path_match: "*.custom_fields.*",
          mapping: { type: :string, index: :no, store: :yes }
        }
      }
    ]
  end

  def build_properties_mapping
    scoped_fields = Cdx.core_field_scopes.select(&:has_searchables?)

    Hash[
      scoped_fields.map { |scope|
        [ scope.name, { "properties" => map_fields(scope.fields).merge(custom_fields_mapping) } ]
      }
    ].with_indifferent_access
  end

  def map_fields fields
    Hash[fields.select(&:has_searchables?).map { |field| [field.name, map_field(field)] }].with_indifferent_access
  end

  def map_field field
    case field.type
    when "nested"
      {
        "type" => "nested",
        "properties" => map_fields(field.sub_fields)
      }
    when "multi_field"
      {
        fields: {
          "analyzed" => {type: :string, index: :analyzed},
          field.name => {type: :string, index: :not_analyzed}
        }
      }
    when "enum"
      {
        "type" => "string",
        "index" => "not_analyzed"
      }
    when "dynamic"
      { "properties" => {} }
    else
      {
        "type" => field.type,
        "index" => "not_analyzed"
      }
    end
  end

  def custom_fields_mapping
    {
      custom_fields: {
        type: 'object'
      }
    }
  end
end