describe Docusign::InlineTemplate do

  let(:template) { FactoryGirl.build(:inline_template, recipients: recipients) }
  let(:sequence) { template.sequence }

  describe "#to_h" do
    subject { template.to_h }

    context "recipients is nil" do
      let(:recipients) { nil }
      it { is_expected.to eq(sequence: sequence.to_s) }
    end

    context "recipients is empty" do
      let(:recipients) { [] }
      it { is_expected.to eq(sequence: sequence.to_s) }
    end

    context "multiple recipients" do
      let(:recipients) { FactoryGirl.build_list(:recipient, 2) }
      let(:first) { recipients.first }
      let(:second) { recipients.second }

      it { is_expected.to eq(
        sequence: sequence.to_s,
        recipients: {
          signers: [first.to_h, second.to_h]
        }
      )}
    end
  end
end
