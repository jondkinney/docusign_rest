describe Docusign::ServerTemplate do

  let(:template) { FactoryGirl.build(:server_template) }
  let(:template_id) { template.template_id }
  let(:sequence) { template.sequence }

  describe "#to_h" do
    subject { template.to_h }
    it { is_expected.to eq(sequence: sequence.to_s, templateId: template_id) }
  end

  describe ".from_template_ids" do
    subject(:server_templates) { Docusign::ServerTemplate.from_template_ids(template_ids) }

    context "template_ids is nil" do
      let(:template_ids) { nil }
      it { is_expected.to eq(nil) }
    end

    context "template_ids is empty" do
      let(:template_ids) { [] }
      it { is_expected.to eq(nil) }
    end

    context "multiple template_ids" do
      let(:template_id1) { generate(:template_id) }
      let(:template_id2) { generate(:template_id) }
      let(:template_ids) { [template_id1, template_id2] }

      its(:size) { is_expected.to eq(2) }
      its(:first) { is_expected.to be_a(Docusign::ServerTemplate) }
      its(:second) { is_expected.to be_a(Docusign::ServerTemplate) }

      context "#first" do
        subject { server_templates.first }
        its(:sequence) { is_expected.to eq(1) }
        its(:template_id) { is_expected.to eq(template_id1) }
      end

      context "#second" do
        subject { server_templates.second }
        its(:sequence) { is_expected.to eq(2) }
        its(:template_id) { is_expected.to eq(template_id2) }
      end
    end
  end

end
