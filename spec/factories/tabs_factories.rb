FactoryGirl.define do

  factory :text_tab, class: Docusign::TextTab do
    id { generate(:tab_id) }
    label 'myTextLabel'
  end

  factory :checkbox_tab, class: Docusign::CheckboxTab do
    id { generate(:tab_id) }
    label 'myCheckboxLabel'
  end

end
