FactoryGirl.define do
  skip_create

  factory :server_template, class: Docusign::ServerTemplate do
    sequence(:sequence) { |n| n }
    template_id
  end

  factory :inline_template, class: Docusign::InlineTemplate do
    sequence(:sequence) { |n| n }

    trait :with_recipients do
      recipients { FactoryGirl.build_list(:recipient, 2) }
    end
  end

  factory :composite_template, class: Docusign::CompositeTemplate do

    trait :with_server_templates do
      server_templates { FactoryGirl.build_list(:server_template, 2) }
    end

    trait :with_inline_templates do
      inline_templates { FactoryGirl.build_list(:inline_template, 2) }
    end
  end

end
