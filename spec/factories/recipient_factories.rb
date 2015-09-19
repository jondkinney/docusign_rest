FactoryGirl.define do
  factory :recipient, class: Docusign::Recipient do
    skip_create

    id { generate(:recipient_id) }
    role_name 'Client'
    name 'John Smith'
    email 'john@gmail.com'

    trait :cco do
      role_name 'Chief Compliance Officer'
      name 'David Nugent'
      email 'dave@wealthsimple.com'
    end

    trait :with_tabs do
      tabs { { given_name: 'John', surname: 'Smith', citizenship: 'Canadian'} }
    end
  end
end
