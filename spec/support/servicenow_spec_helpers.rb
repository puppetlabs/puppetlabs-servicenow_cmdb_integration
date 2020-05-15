def get_node_data_hash(fqdn = 'blah')
  JSON.parse(servicenow(fqdn))['servicenow']
end

def mock_http_with(response)
  expect(Net::HTTP).to receive(:start).with("#{config['instance']}.service-now.com", 443, use_ssl: true, verify_mode: 0).and_return(response)
end

def remove_key_from_json_response(json, key)
  hash = JSON.parse(json)
  _value = hash['result'][0].delete(key)
  hash.to_json
end

def invalidate_classes_json(valid_api_response)
  hash = JSON.parse(valid_api_response)
  hash['result'][0]['u_puppet_classes'] = 'not_real_json'
  hash.to_json
end

def mock_config_yaml
  expect(YAML).to receive(:load_file).and_return(config)
end
