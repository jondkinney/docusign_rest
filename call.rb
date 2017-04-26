require 'docusign_rest'

# email = esign+development@wealthsimple.com
# password = ul9v$@F6w6^x
# accountId = 1098897
# integratorKey = WEAL-b3f41e21-8539-4cfd-9f08-034fa0c814e4

DocusignRest.configure do |config|
 config.username = 'a12ad145-deb3-4224-a946-a60360bed8df'
 config.password = 'ul9v$@F6w6^x'
 config.integrator_key = 'WEAL-b3f41e21-8539-4cfd-9f08-034fa0c814e4'
 config.account_id =  '1098897'
 config.endpoint = 'https://demo.docusign.net/restapi'
 config.api_version    = 'v2'
end


tabs = [
  Docusign::TextTab.new(label: :naaf_given_name, value: 'George'),
  Docusign::TextTab.new(label: :naaf_given_name, value: "George"),
  Docusign::TextTab.new(label: :naaf_surname, value: "Bush"),
  Docusign::CheckboxTab.new(label: :naaf_checkbox_account_type_non_registered, value: true),
  Docusign::CheckboxTab.new(label: :naaf_checkbox_regulatory_employed_by_iiroc_false, value: false),
  Docusign::CheckboxTab.new(label: :naaf_checkbox_regulatory_employed_by_iiroc_true, value: true),
]

client = Docusign::Recipient.new(id: 1, role_name: 'Client', name: 'Karney Li', email: 'karneyli@gmail.com', tabs: tabs, embedded: false )
coo = Docusign::Recipient.new(id: 3, role_name: 'Chief Compliance Officer', name: 'David Nugent', email: 'karney+dave@wealthsimple.com')
shareowner = Docusign::Recipient.new(id: 2, role_name: 'ShareOwner', name: 'Helen Hsia', email: 'karney+helen@wealthsimple.com')

naafTemplate = Docusign::CompositeTemplate.new(['E88FA38C-6D84-485E-9F04-26DD094BA5A9'], [client, shareowner])
wealthsimpleIma = Docusign::CompositeTemplate.new(['89E86A1B-6CE4-4F78-B2A6-A709B9B4D07A'], [client, coo])

envelope = Docusign::Envelope.new(
  composite_templates: [naafTemplate, wealthsimpleIma],
  email: { subject: "Please review and sign the New Account & Agreement Forms for Karney Li" }
)

p envelope.send_envelope!
