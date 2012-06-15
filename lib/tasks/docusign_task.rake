require 'docusign_rest'

namespace :docusign_rest do
  desc "Retrive account_id from the API"
  task :generate_config do
    def ask(message)
      STDOUT.print message
      STDIN.gets.chomp
    end

    STDOUT.puts %Q{
Please do the following:
------------------------
1) Login or register for an account at demo.docusign.net
     ...or their production url if applicable
2) Click 'Preferences' in the upper right corner of the page
3) Click 'API' in far lower left corner of the menu
4) Request a new 'Integrator Key' via the web intervace
     * You will use this key in one of the next steps to retrieve your 'accountId'\n\n}

    username = ask('Please enter your DocuSign username:')
    password = ask('Please enter your Docusign password:')
    integrator_key = ask('Please enter your Docusign integrator_key:')

    DocusignRest.configure do |config|
      config.username       = username
      config.password       = password
      config.integrator_key = integrator_key
    end

    # initialize a client and request the accountId
    client = DocusignRest::Client.new
    acct_id = client.get_account_id

    puts ""

    # construct the configure block for the user with his or her credentials and accountId
    config = %Q{require 'docusign_rest'

DocusignRest.configure do |config|
  config.username       = '#{username}'
  config.password       = '#{password}'
  config.integrator_key = '#{integrator_key}'
  config.account_id     = '#{acct_id}'
end\n\n}

    # write the initializer for the user
    docusign_initializer_path = Rails.root.join("config/initializers/docusign_rest.rb")
    File.open(docusign_initializer_path, 'w') { |f| f.write(config) }

    # read the initializer file into a var for compairision to the config block above
    docusign_initializer_content = File.open(docusign_initializer_path) { |io| io.read }

    # if they match tell the user we wrote the file, otherwise tell them to do it themselves
    if docusign_initializer_content == config
      puts "The following block of code was added to config/initializers/docusign_rest.rb\n\n"
      puts config
    else
      puts %Q{The config file was not able to be automatically created for you.
Please create it at config/initializers/docusign_rest.rb and add the following content:\n\n}
      puts config
    end
  end
end
