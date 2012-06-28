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
      #config.endpoint       = 'https://www.docusign.net'
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

This gem also monkey patches one small part of multipart-post to inject some header values and formatting that DocuSign requires. If you would like to see the monkey patched code please take a look at [lib/multipart-post/parts.rb](https://github.com/j2fly/docusign_rest/blob/master/lib/multipart_post/parts.rb). It's only re-opening one method, but feel free to make sure you understand that code if it concerns you. 

### Examples

* These examples assume you have already run the `docusign_rest:generate_config` rake task and have the configure block properly setup in an initializer with your username, password, integrator\_key, and account\_id. 
* Unless noted otherwise, these requests return the JSON parsed body of the response so you can index the returned hash directly. For example: `template_response["templateId"]`.

**Getting account_id:**

```ruby
client = DocusignRest::Client.new
puts client.get_account_id
```


**Creating an envelope from a document:**

```ruby
client = DocusignRest::Client.new
document_envelope_response = client.create_envelope_from_document(
  email: {
    subject: "test email subject",
    body: "this is the email body and it's large!"
  },
  # If embedded is set to true  in the signers array below, emails
  # don't go out to the signers and you can embed the signature page in an 
  # iFrame by using the client.get_recipient_view method
  signers: [
    {
      #embedded: true,
      name: 'Test Guy',
      email: 'someone@gmail.com'
    },
    {
      #embedded: true,
      name: 'Test Girl',
      email: 'someone+else@gmail.com'
    }
  ],
  files: [
    {path: '/Absolute/path/to/test.pdf', name: 'test.pdf'},
    {path: '/Absolute/path/to/test2.pdf', name: 'test2.pdf'}
  ],
  status: 'sent'
)
```


**Creating a template:**

```ruby
client = DocusignRest::Client.new
@template_response = client.create_template(
  description: 'Template Description',
  name: "Template Name",
  signers: [
    {
      embedded: true,
      name: 'jon',
      email: 'someone@gmail.com',
      role_name: 'Issuer',
      anchor_string: 'issuer_sig'
    },
    {
      embedded: true,
      name: 'tim',
      email: 'someone+else@gmail.com',
      role_name: 'Attorney',
      anchor_string: 'attorney_sig'
    }
  ],
  files: [
    {path: '/Absolute/path/to/test.pdf', name: 'test.pdf'}
  ]
)
```


**Creating an envelope from a template:**

```ruby
client = DocusignRest::Client.new
@envelope_response = client.create_envelope_from_template(
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
    },
    {
      embedded: true,
      name: 'tim',
      email: 'someone+else@gmail.com',
      role_name: 'Attorney'
    }
  ]
)
```


**Retrieving the url for embedded signing. (Returns a string, not a hash)**

```ruby
client = DocusignRest::Client.new
@url = client.get_recipient_view(
  envelope_id: @envelope_response["envelopeId"],
  name: current_user.full_name,
  email: current_user.email,
  return_url: 'http://google.com'
)
```


**Check status of an envelope including the signers hash w/ the status of each signer**

```ruby
client = DocusignRest::Client.new
response = client.get_envelope_recipients(
  envelope_id: @envelope_response["envelopeId"],
  include_tabs: true,
  include_extended: true
)
```

**Retrieve a document from an envelope and store it at a local file path**

```ruby
client = DocusignRest::Client.new
client.get_document_from_envelope(
  envelope_id: @envelope_response["envelopeId"],
  document_id: 1,
  local_save_path: "#{Rails.root.join('docusign_docs/file_name.pdf')}"
)
```

## Breaking out of the iFrame after signing

In order to return to your application after the signing process is complete it's important to have a way to evaluate whether or not the signing was successful and then do something about each case. The way I set this up was to render the embedded signing iframe for a controller action called 'embedded_signing' and specify the return_url of the `client.get_recipient_view` API call to be something like: http://myapp.com/docusign_response. Then in the same controller as the embedded_signing method, define the docusign_response method. This is where the signing process will redirect to after the user is done interacting with the DocuSign iframe. DocuSign passes a query string parameter in the return_url named 'event' and you can check like so: `if params[:event] == "signing_complete"` then you'll want to redirect to another spot in your app, not in the iframe. To do so, we need to use JavaScript to access the iframe's parent and set it's location to the path of our choosing. To do this, instanciate the DocusignRest::Utility class and call the breakout_path method like this:

```ruby    
class SomeController < ApplicationController

  # the view corresponding to this action has the iFrame in it with the
  # @url as it's src. @envelope_response is populated from either:
  # @envelope_response = client.create_envelope_from_document
  # or
  # @envelope_response = client.create_envelope_from_template
  def embedded_signing
    client = DocusignRest::Client.new
    @url = client.get_recipient_view(
      envelope_id: @envelope_response["envelopeId"],
      name: current_user.display_name,
      email: current_user.email,
      return_url: "http://localhost:3000/docusign_response"
    )
  end

  def docusign_response
    utility = DocusignRest::Utility.new

    if params[:event] == "signing_complete"
      flash[:notice] = "Thanks! Successfully signed"
      render :text => utility.breakout_path(some_path), content_type: :html
    else
      flash[:notice] = "You chose not to sign the document."
      render :text => utility.breakout_path(some_other_path), content_type: :html
    end
  end

end
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

The test suite uses VCR and is configured to record all requests by using the 'all' configuration option surrounding each API request. If you want to speed up the test suite locally for new feature development, you may want to change the VCR config record setting to 'once' temporarily which will not write a new YAML file for each request each time you hit the API and significantly speed up the tests. However, this can lead to false passing tests as the gem changes so it's recommended that you ensure all tests pass by actually hitting the API before submitting a pull request.
