require_relative '../lib/docusign_rest'

DocusignRest.configure do |config|
  config.username       = 'jonkinney@gmail.com'
  config.password       = 'MnUWneAH3xqL2G'
  config.integrator_key = 'NAXX-93c39e8c-36c4-4cb5-8099-c4fcedddd7ad'
  config.account_id     = '327367'
  config.endpoint       = 'https://demo.docusign.net/restapi'
  config.api_version    = 'v2'
end

client = DocusignRest::Client.new

response = client.create_envelope_from_document(
  email: {
    subject: 'Test email subject',
    body: 'This is the email body.'
  },
  # If embedded is set to true  in the signers array below, emails don't go out
  # and you can embed the signature page in an iFrame by using the
  # get_recipient_view method
  signers: [
    {
      #embedded: true,
      name: 'Test Guy',
      email: 'someone@example.com'
    },
    {
      #embedded: true,
      name: 'Test Girl',
      email: 'someone+else@example.com'
    }
  ],
  files: [
    { path: 'test.pdf', name: 'test.pdf' },
    { path: 'test2.pdf', name: 'test2.pdf' }
  ],
  status: 'sent'
)

puts response #the response is a parsed JSON string
