# DocusignRest

This 'wrapper gem' hooks a Ruby app (currently only tested with Rails) up to the DocuSign REST API to allow for embedded signing.

## Installation

Add this line to your application's Gemfile:

    gem 'docusign_rest'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docusign_rest

## Configuration

There is a bundled rake task that will prompt you for your DocuSign credentials including:

  * Username
  * Password
  * Integrator Key

and create the config/initializers/docusign\_rest.rb file for you. If the file was unable to be created the rake task will output the config block for you to manually add to an initializer.

    $ bundle exec rake docusign_rest:generate_config

outputs:

    Please do the following:
    ------------------------
    1) Login or register for an account at demo.docusign.net
        ...or their production url if applicable
    2) Click 'Preferences' in the upper right corner of the page
    3) Click 'API' in far lower left corner of the menu
    4) Request a new 'Integrator Key' via the web intervace
        * You will use this key in one of the next steps to retrieve your 'accountId'

    Please enter your DocuSign username:jon.kinney@bolstr.com
    Please enter your Docusign password:p@ssw0rd1
    Please enter your Docusign integrator_key:KEYS-19ddd1cc-cb56-4ca6-87ec-38db47d14b32

    The following block of code was added to config/initializers/docusign_rest.rb

    require 'docusign_rest'

    DocusignRest.configure do |config|
      config.username       = 'jon.kinney@bolstr.com'
      config.password       = 'p@ssw0rd1'
      config.integrator_key = 'KEYS-19ddd1cc-cb56-4ca6-87ec-38db47d14b32'
      config.account_id     = '123456'
    end

## Usage

This gem makes creating multipart POST (aka file upload) requests to the DocuSign REST API dead simple. It's built on top of Net:HTTP and utilizes the [multipart-post](https://github.com/nicksieger/multipart-post) gem to assist with formatting the request for the DocuSign REST API which requires that all files be embedded as JSON directly in the request body, not the body\_stream like multipart-post does by default. This gem also monkeypatches one small part of multipart-post to inject some header values and formatting that DocuSign requires. If you would like to see the monkeypatched code please take a look at lib/multipart-post/parts.rb. It's only re-opening one method, but feel free to make sure you understand that monkeypatch if it concerns you. 

### Examples

* These examples assume you have already run the rake task and have the configure block properly setup with your username, password, integrator\_key, and account\_id.

**Getting login\_information:**

    client = DocusignRest::Client.new
    puts client.get_account_id


**Creating an envelope from a document:**

    client = DocusignRest::Client.new
    response = client.create_envelope_from_template(
                description: 'New Dec',
                name: 'New Name',
                email: {
                  subject: "test email subject",
                  body: "this is the email body and it's large!"
                },
                signers: [
                  {
                    email: 'jon.kinney@bolstr.com',
                    name: 'Jon Kinney',
                    anchor_tab_string: 'sign here'
                  }
                ],
                files: [
                  {path: 'test.pdf', name: 'test.pdf'}
                ]
              )
    puts response.body


**Creating a template:**

    response = @client.create_template(
      description: 'Nice Template!',
      name: "Templatio",
      signers: [
        {
          email: 'jon.kinney@bolstr.com',
          name: 'Jon Kinney',
          role_name: 'Issuer',
          anchor_string: 'sign here'
        }
      ],
      files: [
        {path: 'test.pdf', name: 'test.pdf'}
      ]
    )
    @template_response = JSON.parse(response.body)


**Creating an envelope from a template:**

    response = @client.create_envelope_from_template(
      status: 'sent',
      email: {
        subject: "The test email subject envelope",
        body: "Envelope body content here"
      },
      template_id: @template_response["templateId"],
      template_roles: [
        {
          email: 'jon.kinney@bolstr.com',
          name: 'Jon Kinney',
          role_name: 'Issuer'
        }
      ]
    )
    @envelope_response = JSON.parse(response.body)


**Retrieving the url for embedded signing**

    response = @client.get_recipient_view(
      envelope_id: @envelope_response["envelopeId"],
      email: 'jon.kinney@bolstr.com',
      return_url: 'http://google.com',
      user_name: 'Jon Kinney'
    )
    @view_recipient_response = JSON.parse(response.body)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
