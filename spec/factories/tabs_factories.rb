FactoryGirl.define do
  skip_create

  factory :text_tab, class: Docusign::TextTab do
    label 'myTextLabel'
  end

  factory :checkbox_tab, class: Docusign::CheckboxTab do
    label 'myCheckboxLabel'
  end

  factory :tab, class: Docusign::Tab do
    label 'someTab'
  end

end
