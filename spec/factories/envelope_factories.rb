FactoryGirl.define do

  factory :envelope, class: Docusign::Envelope do
    skip_create

    trait :with_envelope_id do
      id { generate(:envelope_id) }
    end

    trait :with_recipients do
      recipients { [build(:recipient, :with_tabs), build(:recipient, :cco)] }
    end

    trait :with_template_ids do
      template_ids { [generate(:template_id), generate(:template_id)] }
    end
  end

end
