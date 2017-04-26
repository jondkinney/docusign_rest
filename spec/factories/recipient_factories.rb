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
      tabs do
        [
          build(:text_tab, label: :naaf_given_name, value: 'Jack'),
          build(:text_tab, label: :naaf_surname, value: 'Smith'),
          build(:text_tab, label: :naaf_dob_year, value: '1984'),
          build(:text_tab, label: :naaf_dob_month, value: '05'),
          build(:text_tab, label: :naaf_address, value: nil),
          build(:checkbox_tab, label: :naaf_us_person_yes, value: true),
          build(:checkbox_tab, label: :naaf_us_person_no, value: false),
        ]
      end
    end
  end
end
