FactoryGirl.define do

  factory :envelope, class: Docusign::Envelope do
    skip_create

    trait :with_email do
      email { { subject: 'email subject', body: 'email body' } }
    end

    trait :with_composite_templates do
      composite_templates { FactoryGirl.create_list(:composite_template, 2, :with_server_templates, :with_inline_templates) }
    end

  end
end
