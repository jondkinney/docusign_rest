FactoryGirl.define do
    sequence(:template_id) { SecureRandom.uuid }
    sequence(:envelope_id) { SecureRandom.uuid }
    sequence(:tab_id) { |n| SecureRandom.uuid }
    sequence(:recipient_id) { |n| n }
end
