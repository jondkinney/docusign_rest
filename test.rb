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
             signers: [
               {email: 'test_guy@gmail.com', name: 'Test Guy'},
               {email: 'test_girl@gmail.com', name: 'Test Girl'},
             ],
             files: [
               {path: 'test.pdf', name: 'test.pdf'},
               {path: 'test2.pdf', name: 'test2.pdf'}
             ],
             status:        'sent'
           )

puts response.body
