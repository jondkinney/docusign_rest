describe Docusign::Template do

  let(:sequence) { 5 }
  let(:template) { described_class.new(sequence: sequence) }

  describe "#to_h" do
    subject { template.to_h }

    context "sequence is a number" do
      it { is_expected.to eq(sequence: sequence.to_s) }
    end

    context "sequence is some string" do
      let(:sequence) { "one" }
      it { is_expected.to eq(sequence: sequence) }
    end

    context "sequence is nil" do
      let(:sequence) { nil }
      it { is_expected.to eq({}) }
    end
  end


end
