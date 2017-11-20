# DocusignRest

This 'wrapper gem' hooks a Ruby app (currently only tested with Rails) up to the [DocuSign](http://www.docusign.com/) REST API ([docs](https://docs.docusign.com/esign/), [API explorer](https://apiexplorer.docusign.com/#/esign/restapi)) to allow for embedded signing.

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
    1) Login or register for an account at https://demo.docusign.net
         ...or their production url if applicable
    2) From the Avatar menu in the upper right hand corner of the page, click "Go to Admin"
    3) From the left sidebar menu, click "API and Keys"
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
      #config.endpoint       = 'https://www.docusign.net/restapi'
      #config.api_version    = 'v2'
    end


### Config Options

There are several other configuration options available but the two most likely to be needed are:

```ruby
config.endpoint       = 'https://docusign.net/restapi'
config.api_version    = 'v2'
config.open_timeout   = 2 # default value is 5
config.read_timeout   = 5 # default value is 10
```

The above options allow you to change the endpoint (to be able to hit the production DocuSign API, for instance) and to modify the API version you wish to use.

## Usage

The docusign\_rest gem makes creating multipart POST (aka file upload) requests to the DocuSign REST API dead simple. It's built on top of `Net::HTTP` and utilizes the [multipart-post](https://github.com/nicksieger/multipart-post) gem to assist with formatting the multipart requests. The DocuSign REST API requires that all files be embedded as JSON directly in the request body (not the body\_stream like multipart-post does by default) so the docusign\_rest gem takes care of [setting that up for you](https://github.com/j2fly/docusign_rest/blob/master/lib/docusign_rest/client.rb#L397).

### Examples

* Unless noted otherwise, these requests return the JSON parsed body of the response so you can index the returned hash directly. For example: `template_response["templateId"]`.

#### Situations

**In the context of a Rails app**

This is how most people are using this gem - they've got a Rails app that's doing things with the Docusign API.  In that case, these examples assume you have already set up a docusign account, have run the `docusign_rest:generate_config` rake task, and have the configure block properly setup in an initializer with your username, password, integrator\_key, and account\_id.

**In the context of this gem as a standalone project**

Ideally this gem will be independent of Rails.  If that's your situation, there won't be a Rails initializer so your code will need to load the API authentication credentials.  You will want to do something like:

```ruby
load 'test/docusign_login_config.rb'
client = DocusignRest::Client.new
client.get_account_id
document_envelope_response = client.create_envelope_from_document( # etc etc
```

#### Example code

**Getting account_id:**

```ruby
client = DocusignRest::Client.new
puts client.get_account_id
```

**Creating an envelope from a document:**

Here's how to create an envelope from a local PDF file and open a browser to the URL for the recipient:

```ruby
client = DocusignRest::Client.new
document_envelope_response = client.create_envelope_from_document(
  email: {
    subject: "test email subject",
    body: "this is the email body and it's large!"
  },
  # If embedded is set to true in the signers array below, emails
  # don't go out to the signers and you can embed the signature page in an
  # iframe by using the client.get_recipient_view method
  signers: [
    {
      embedded: true,
      name: 'Joe Dimaggio',
      email: 'joe.dimaggio@example.org',
      role_name: 'Issuer',
      sign_here_tabs: [
        {
          anchor_string: 'sign here',
          anchor_x_offset: '-30',
          anchor_y_offset: '35'
        }
      ]
    },
  ],
  files: [
    {path: '/Absolute/path/to/test.pdf', name: 'test.pdf'},
  ],
  status: 'sent'
)
url = client.get_recipient_view(envelope_id: document_envelope_response['envelopeId'], name: "Joe Dimaggio", email: "joe.dimaggio@example.org", return_url: 'http://google.com')['url']
`open #{url}`
```

Note: In the example below there are two sign here tabs for the user with a role of 'Attorney'. There are also two documents attached to the envelope, however, this exact configuration would only allow for signature on the first document. If you need signature for a second document, you'll need to add further options, namely: `document_id: 2` in one of the `sign_here_tabs` so that DocuSign knows where to embed that signature tab.

```ruby
client = DocusignRest::Client.new
document_envelope_response = client.create_envelope_from_document(
  email: {
    subject: "test email subject",
    body: "this is the email body and it's large!"
  },
  # If embedded is set to true  in the signers array below, emails
  # don't go out to the signers and you can embed the signature page in an
  # iframe by using the client.get_recipient_view method
  signers: [
    {
      embedded: true,
      name: 'Test Guy',
      email: 'someone@gmail.com',
      role_name: 'Issuer',
      sign_here_tabs: [
        {
          anchor_string: 'sign here',
          anchor_x_offset: '-30',
          anchor_y_offset: '35'
        }
      ]
    },
    {
      embedded: true,
      name: 'Test Girl',
      email: 'someone+else@gmail.com',
      role_name: 'Attorney',
      sign_here_tabs: [
        {
          anchor_string: 'sign_here_2',
          anchor_x_offset: '140',
          anchor_y_offset: '8'
        },
        {
          anchor_string: 'sign_here_3',
          anchor_x_offset: '140',
          anchor_y_offset: '8'
        }
      ]
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
      sign_here_tabs: [
        {
          anchor_string: 'issuer_sig',
          anchor_x_offset: '140',
          anchor_y_offset: '8'
        }
      ]
    },
    {
      embedded: true,
      name: 'tim',
      email: 'someone+else@gmail.com',
      role_name: 'Attorney',
      sign_here_tabs: [
        {
          anchor_string: 'attorney_sig',
          anchor_x_offset: '140',
          anchor_y_offset: '8'
        }
      ]
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

**Creating an envelope from a template using custom tabs:**

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
      role_name: 'Issuer',
      text_tabs: [
        {
          label: 'Seller Full Name',
          name: 'Seller Full Name',
          value: 'Jon Doe'
        }
      ]
    },
    {
      embedded: true,
      name: 'tim',
      email: 'someone+else@gmail.com',
      role_name: 'Attorney',
      text_tabs: [
        {
          label: 'Attorney Full Name',
          name: 'Attorney Full Name',
          value: 'Tim Smith'
        }
      ]
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

**Void an envelope**

```ruby
client = DocusignRest::Client.new
client.void_envelope(
  envelope_id: @envelope_response["envelopeId"],
  voided_reason: 'Reason provided by the user'
)
```

## Breaking out of the iframe after signing

In order to return to your application after the signing process is complete it's important to have a way to evaluate whether or not the signing was successful and then do something about each case. The way I set this up was to render the embedded signing iframe for a controller action called 'embedded_signing' and specify the return_url of the `client.get_recipient_view` API call to be something like: http://myapp.com/docusign_response. Then in the same controller as the embedded_signing method, define the docusign_response method. This is where the signing process will redirect to after the user is done interacting with the DocuSign iframe. DocuSign passes a query string parameter in the return_url named 'event' and you can check like so: `if params[:event] == "signing_complete"` then you'll want to redirect to another spot in your app, not in the iframe. To do so, we need to use JavaScript to access the iframe's parent and set it's location to the path of our choosing. To do this, instantiate the `DocusignRest::Utility` class and call the breakout_path method like this:

```ruby
class SomeController < ApplicationController

  # the view corresponding to this action has the iframe in it with the
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
      render :text => utility.breakout_path(some_path), content_type: 'text/html'
    else
      flash[:notice] = "You chose not to sign the document."
      render :text => utility.breakout_path(some_other_path), content_type: 'text/html'
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

    $ bundle exec ruby lib/tasks/docusign_task.rb

This calls a rake task which adds a non-version controlled file in the test folder called `docusign_login_config.rb` which holds your account specific credentials and is required in order to hit the test API through the test suite.

**VCR**

The test suite uses VCR and is configured to record all requests by using the 'all' configuration option surrounding each API request. If you want to speed up the test suite locally for new feature development, you may want to change the VCR config record setting to 'once' temporarily which will not write a new YAML file for each request each time you hit the API and significantly speed up the tests. However, this can lead to false passing tests as the gem changes so it's recommended that you ensure all tests pass by actually hitting the API before submitting a pull request.

**SSL Issue**

In the event that you have an SSL error running the tests, such as;

    SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed

there is a sample cert 'cacert.pem' you can use when executing the
test suite.

    SSL_CERT_FILE=cacert.pem guard
    SSL_CERT_FILE=cacert.pem ruby lib/tasks/docusign_task.rb
