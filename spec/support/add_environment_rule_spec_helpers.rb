def assert_task_error(e, msg_regex, kind, details = {})
  expect(e).to be_a(TaskHelper::Error)
  expect(e.message).to match(msg_regex)
  expect(e.kind).to eql(kind)
  expect(e.details).to eql(details)
end

def construct_env_rule(environment)
  ['=', ['trusted', 'external', 'servicenow', 'puppet_environment'], environment]
end
