RSpec.describe Pubid::Nist::NistTechPubs, vcr: true do
  describe "#fetch" do
    it "fetches doi identifiers" do
      expect(described_class.fetch.map { |d| d[:doi] })
        .to include("NBS.BH.1",
                    "NIST.SP.1800-15",
                    "NIST.SP.1265",
                    "NBS.FIPS.83",
                    "NIST.IR.8379")
    end
  end

  describe "#convert" do
    it "converts old pubid to new NIST PubID" do
      expect(described_class.convert({ doi: "NISTIR.8379" }).to_s)
        .to eq("NIST IR 8379")
    end

    it "keeps correct NIST PubID the same" do
      expect(described_class.convert({ doi: "NIST.SP.800-133r2" }).to_s(format = :mr))
        .to eq("NIST.SP.800-133r2")
      expect(described_class.convert({ doi: "NIST.SP.800-160v1" }).to_s(format = :mr))
        .to eq("NIST.SP.800-160v1")
    end
  end

  describe "#comply_with_pubid" do
    before do
      described_class.documents = [
        { id: "NIST SP 260-14",
          doi: "NIST.SP.260-14",
          title: "NIST SP 260-14" },
      ]
    end

    it "returns identifier comply with NIST PubID" do
      expect(described_class.comply_with_pubid.map { |d| d[:id] })
        .to include("NIST SP 260-14")
    end
  end

  describe "#different_with_pubid" do
    before do
      described_class.documents = [
        { id: "NISTIR 8379",
          doi: "NIST.IR.8379",
          title: "NISTIR 8379" },
      ]
    end

    it "returns identifiers not comply with NIST PubID" do
      expect(described_class.different_with_pubid.map { |d| d[:id] })
        .to include("NISTIR 8379")
    end
  end

  describe "#parse_fail_with_pubid" do
    before do
      described_class.documents = [
        { id: "NBS CIRC e",
          doi: "NBS.CIRC.e",
          title: "NBS CIRC e" },
      ]
    end

    it "returns identifiers fail to parse" do
      expect(described_class.parse_fail_with_pubid.map { |d| d[:id] })
        .to include("NBS CIRC e")
    end
  end

  describe "#status" do
    let(:id) { "LCIRC 897" }
    let(:doi) { "NBS.LCIRC.897" }
    let(:mr) { "NBS.LC.897" }
    let(:title) do
      "Letter Circular 897: tables for transforming chromaticity coordinates"\
        " from the I.C.I system to the R-U-C-S system"
    end
    let(:finalPubId) { "NBS LC 897" }

    before do
      described_class.documents = [
        { doi: doi,
          title: title },
      ]
    end

    subject { described_class.status }

    it do
      expect(subject.to_a)
        .to eq([
                 { doi: doi, title: title, mr: mr, finalPubId: finalPubId },
               ])
    end

    context "when cannot parse id and doi" do
      let(:id) { "NBS CIRC e" }
      let(:doi) { "NBS.CIRC.e" }

      it do
        expect(subject.to_a)
          .to eq([
                   { doi: doi, title: title, finalPubId: "parse error",
                     mr: "parse_error" },
                 ])
      end
    end
  end
end
