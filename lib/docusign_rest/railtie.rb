require 'docusign_rest'
require 'rails'
module DocusignRest
  class Railtie < Rails::Railtie
    railtie_name :docusign_rest

    rake_tasks do
      load 'tasks/docusign_task.rake'
    end
  end
end
