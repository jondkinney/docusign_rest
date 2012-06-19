require 'rake'
require 'json'

Rake.application.rake_require '../lib/tasks/docusign_task'
Rake.application['docusign_rest:generate_config'].invoke
