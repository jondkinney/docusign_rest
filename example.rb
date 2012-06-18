require 'docusign_rest'

DocusignRest.configure do |config|
  config.username       = "someone@gmail.com"
  config.password       = "password"
  config.integrator_key = "KEYS-16dbc1bc-ca56-4ea6-87ec-29db47d94b32"
  config.account_id     = "123456"
end

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
      email: 'someone+else@gmail.com'
    }
  ],
  files: [
    {path: 'test.pdf', name: 'test.pdf'},
    {path: 'test2.pdf', name: 'test2.pdf'}
  ],
  status: 'sent'
)

response = JSON.parse(response.body)
puts response.body
