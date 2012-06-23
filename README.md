# DocusignRest

This 'wrapper gem' hooks a Ruby app (currently only tested with Rails) up to the [DocuSign](http://www.docusign.com/) [REST API](http://www.docusign.com/developer-center) to allow for embedded signing.

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

and create the `config/initializers/docusign_rest.rb` file in your Rails app for you. If the file was unable to be created, the rake task will output the config block for you to manually add to an initializer.

**Note** please run the below task and ensure your initializer is in place before attempting to use any of the methods in this gem. Without the initializer this gem will not be able to properly authenticate you to the DocuSign REST API.

    $ bundle exec rake docusign_rest:generate_config

outputs:

    Please do the following:
    ------------------------
    1) Login or register for an account at demo.docusign.net
        ...or their production url if applicable
    2) Click 'Preferences' in the upper right corner of the page
    3) Click 'API' in far lower left corner of the menu
    4) Request a new 'Integrator Key' via the web interface
        * You will use this key in one of the next steps to retrieve your 'accountId'

    Please enter your DocuSign username: someone@gmail.com
    Please enter your DocuSign password: p@ssw0rd1
    Please enter your DocuSign integrator_key: KEYS-19ddd1cc-cb56-4ca6-87ec-38db47d14b32

    The following block of code was added to config/initializers/docusign_rest.rb

    require 'docusign_rest'

    DocusignRest.configure do |config|
      config.username       = 'someone@gmail.com'
      config.password       = 'p@ssw0rd1'
      config.integrator_key = 'KEYS-19ddd1cc-cb56-4ca6-87ec-38db47d14b32'
      config.account_id     = '123456'
      #config.endpoint       = 'https://docusign.net'
      #config.api_version    = 'v1'
    end


### Config Options

There are several other configuration options available but the two most likely to be needed are:

```ruby
config.endpoint       = 'https://docusign.net'
config.api_version    = 'v1'
```

The above options allow you to change the endpoint (to be able to hit the production DocuSign API, for instance) and to modify the API version you wish to use. If there is a big change in the API it's likely that this gem will need to be updated to leverage changes on the DocuSign side. However, it doesn't hurt to provide the option in case there are several minor updates that do not break functionality but would otherwise require a new gem release. These config options have existed since the gem was created, but in v0.0.3 and above, the options are auto-generated in the config file as comments to make them easier to discover.


## Usage

The docusign\_rest gem makes creating multipart POST (aka file upload) requests to the DocuSign REST API dead simple. It's built on top of Net:HTTP and utilizes the [multipart-post](https://github.com/nicksieger/multipart-post) gem to assist with formatting the multipart requests. The DocuSign REST API requires that all files be embedded as JSON directly in the request body (not the body\_stream like multipart-post does by default) so the docusign\_rest gem takes care of [setting that up for you](https://github.com/j2fly/docusign_rest/blob/master/lib/docusign_rest/client.rb#L397). 

This gem also monkey patches one small part of multipart-post to inject some header values and formatting that DocuSign requires. If you would like to see the monkey patched code please take a look at [lib/multipart-post/parts.rb](https://github.com/j2fly/docusign_rest/blob/master/lib/multipart_post/parts.rb). It's only re-opening one method, but feel free to make sure you understand that monkey patch if it concerns you. 

### Examples

* These examples assume you have already run the `docusign_rest:generate_config` rake task and have the configure block properly setup in an initializer with your username, password, integrator\_key, and account\_id.

**Getting login information:**

```ruby
client = DocusignRest::Client.new
puts client.get_account_id
```


**Creating an envelope from a document:**

```ruby
client = DocusignRest::Client.new
response = client.create_envelope_from_document(
  email: {
    subject: "test email subject",
    body: "this is the email body and it's large!"
  },
  # If embedded is set to true  in the signers array below, emails
  # don't go out and you can embed the signature page in an iFrame
  # by using the get_recipient_view method
  signers: [
    {
      #embedded: true,
      name: 'Test Guy',
      email: 'someone@gmail.com'
    },
    {
      #embedded: true,
      name: 'Test Girl',
      email: 'someone@gmail.com'
    }
  ],
  files: [
    {path: 'test.pdf', name: 'test.pdf'},
    {path: 'test2.pdf', name: 'test2.pdf'}
  ],
  status: 'sent'
)
response = JSON.parse(response.body)
```


**Creating a template:**

```ruby
client = DocusignRest::Client.new
response = client.create_template(
  description: 'Cool Description',
  name: "Cool Template Name",
  signers: [
    {
      embedded: true,
      name: 'jon',
      email: 'someone@gmail.com',
      role_name: 'Issuer',
      anchor_string: 'sign here'
    }
  ],
  files: [
    {path: 'test.pdf', name: 'test.pdf'}
  ]
)
@template_response = JSON.parse(response.body)
```


**Creating an envelope from a template:**

```ruby
client = DocusignRest::Client.new
response = client.create_envelope_from_template(
  status: 'sent',
  email: {
    subject: "The test email subject envelope",
    body: "Envelope body content here"
  },
  template_id: @template_response["templateId"],
  signers: [
    {
      embedded: true,
      name: 'jon',
      email: 'someone@gmail.com',
      role_name: 'Issuer'
    }
  ]
)
@envelope_response = JSON.parse(response.body)
```


**Retrieving the url for embedded signing**

```ruby
client = DocusignRest::Client.new
response = client.get_recipient_view(
  envelope_id: @envelope_response["envelopeId"],
  name: 'jon',
  email: 'someone@gmail.com',
  return_url: 'http://google.com'
)
@view_recipient_response = JSON.parse(response.body)
puts @view_recipient_response["url"]
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`) making sure to write tests to ensure nothing breaks
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

### Running the tests

In order to run the tests you'll need to register for a (free) DocuSign developer account. After doing so you'll have a username, password, and integrator key. Armed with that information execute the following ruby file:

    $ ruby lib/tasks/docusign_task.rb

This calls a rake task which adds a non-version controlled file in the test folder called `docusign_login_config.rb` which holds your account specific credentials and is required in order to hit the test API through the test suite.

**VCR**

The test suite uses VCR and is configured to record only the first request by using the 'once' configuration option surrounding each API request. If you want to experiment with the API or are getting several errors with the test suite, you may want to change the VCR config record setting to 'all' temporarily which will write a new YAML file for each request each time you hit the API. However, this significantly slow down tests and essentially negates the benefit of VCR which is to mock out the API entirely and keep the tests speedy.
