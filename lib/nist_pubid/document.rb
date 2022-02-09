# frozen_string_literal: true

require "json"

UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../update_codes.yaml"))

REVISION_DESC = {
  long: ", Revision ",
  abbrev: ", Rev. ",
  short: "r",
  mr: "r",
}.freeze

VERSION_DESC = {
  long: ", Version ",
  abbrev: ", Ver. ",
  short: "ver",
  mr: "ver",
}.freeze

VOLUME_DESC = {
  long: ", Volume ",
  abbrev: ", Vol. ",
  short: "v",
  mr: "v",
}.freeze

PART_DESC = {
  long: " Part ",
  abbrev: " Pt. ",
  short: "pt",
  mr: "pt",
}.freeze

EDITION_DESC = {
  long: " Edition ",
  abbrev: " Ed. ",
  short: "e",
  mr: "e",
}.freeze

SUPPLEMENT_DESC = {
  long: " Supplement ",
  abbrev: " Suppl. ",
  short: "sup",
  mr: "sup",
}.freeze

SECTION_DESC = {
  long: " Section ",
  abbrev: " Sec. ",
  short: "sec",
  mr: "sec",
}.freeze

APPENDIX_DESC = {
  long: " Appendix ",
  abbrev: " App. ",
  short: "app",
  mr: "app",
}.freeze

ERRATA_DESC = {
  long: " Errata ",
  abbrev: " Err. ",
  short: "err",
  mr: "err",
}.freeze

INDEX_DESC = {
  long: " Index ",
  abbrev: " Index. ",
  short: "indx",
  mr: "indx",
}.freeze

INSERT_DESC = {
  long: " Insert ",
  abbrev: " Ins. ",
  short: "ins",
  mr: "ins",
}.freeze

module NistPubid
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume,
                  :part, :addendum, :stage, :translation, :update_number,
                  :edition, :supplement, :update_year, :section, :appendix,
                  :errata, :index, :insert

    def initialize(publisher:, serie:, docnumber:, **opts)
      @publisher = publisher
      @serie = serie #Serie.new(serie: serie)
      @code = docnumber
      opts.each { |key, value| send("#{key}=", value) }
    end

    # returns weight based on amount of defined attributes
    def weight
      instance_variables.inject(0) do |sum, var|
        sum + (instance_variable_get(var).nil? ? 0 : 1)
      end
    end

    def ==(other)
      other.instance_variables.each do |var|
        return false if instance_variable_get(var) != other.instance_variable_get(var)
      end
      true
    end

    def merge(document)
      document.instance_variables.each do |var|
        val = document.instance_variable_get(var)
        current_val = instance_variable_get(var)
        if [:@serie, :@publisher].include?(var) ||
            (val && current_val.nil?) ||
            (val && current_val.to_s.length < val.to_s.length)
          instance_variable_set(var, val)
        end
      end

      self
    end

    def self.update_old_code(code)
      UPDATE_CODES.each do |from, to|
        code = code.gsub(from, to)
      end
      code
    end

    def self.parse(code)
      code = update_old_code(code)
      return DocumentTransform.new.apply(DocumentParser.new.parse(code))
    rescue Parslet::ParseFailed => failure
      raise "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

      # matches = {
      #   publisher: Publisher.parse(code),
      #   stage: Stage.parse(code),
      #   addendum: match(/(?<=(\.))?(add(?:-\d+)?|Addendum)/, code),
      #   section: /(?<=sec)\d+/.match(code)&.to_s,
      #   appendix: /\d+app/.match(code)&.to_s,
      #   errata: /-errata|\d+err(?:ata)?/.match(code)&.to_s,
      #   index: /\d+index|\d+indx/.match(code)&.to_s,
      #   insert: /\d+ins(?:ert)?/.match(code)&.to_s,
      # }
      #
      # matches[:serie] = Serie.parse(code, matches[:publisher])
      # unless matches[:serie]
      #   raise Errors::ParseError.new("failed to parse serie for #{code}")
      # end
      #
      # code_original = code
      #
      # unless ["NBS CSM", "NBS CS", "NBS RPT"].include?(matches[:serie].to_s)
      #   parsed_volume, volume = matches[:serie].parse_volume(code)
      #   if volume
      #     matches[:volume] = volume
      #     # replace last occurrence
      #     code = code.reverse.sub(parsed_volume.reverse, "").reverse
      #   end
      # end
      #
      # parsed_part, part = matches[:serie].parse_part(code)
      # if part
      #   matches[:part] = part
      #   # replace last occurrence
      #   code = code.reverse.sub(parsed_part.reverse, "").reverse
      # end
      # matches[:edition] = Edition.parse(code, matches[:serie])
      #
      # code = code.sub(matches[:edition].parsed, "") if matches[:edition]
      #
      # version = /(?<=\.)?(?:(?:ver)((?(1)[-\d]|[.\d])+|\d+)|(?:v)(\d+\.[.\d]+))/
      #   .match(code)
      # if version
      #   code = code.sub(version.to_s, "")
      #   matches[:version] = version.to_a[1..-1]&.compact&.first&.gsub(/-/, ".")
      # end
      #
      # unless matches[:stage].nil?
      #   code = code.sub(matches[:stage].original_code, "")
      # end
      #
      # translation = /\((\w{3})\)|\.(spa|zho|vie|por|ind)/.match(code)
      # if translation
      #   code = code.sub(translation.to_s, "")
      #   matches[:translation] = translation.captures.join
      # end
      #
      # matches[:revision] = matches[:serie].parse_revision(code)
      #
      # matches[:supplement] = matches[:serie].parse_supplement(code_original)
      #
      # update = matches[:serie].parse_update(code)
      #
      # (matches[:update_number], matches[:update_year]) = update if update
      #
      # matches[:revision] = nil if matches[:addendum]
      #
      # matches[:docnumber] = matches[:serie].parse_docnumber(code, code_original)
      #
      # # part, edition, supplement, revision, docnumber, volume
      #
      # # NIST GCR documents often have a 3-part identifier -- the last part is
      # # not revision but is part of the identifier.
      # if matches[:serie].to_s == "NIST GCR" && matches[:revision]
      #   matches[:docnumber] += "-#{matches[:revision]}"
      #   matches[:revision] = nil
      # end
      #
      # matches[:serie] = SERIES["mr"].invert[matches[:serie].to_s] || matches[:serie].to_s
      # # matches[:serie].gsub!(/\./, " ")
      #
      # new(**matches)
    # end

    def self.match(regex, code)
      regex.match(code)&.to_s
    end

    def to_s(format = :short)
      result = render_serie(format)
      result += " " unless format == :short || stage.nil?
      result += "#{stage&.to_s(format)}"\
                " #{code.upcase}#{render_part(format)}#{render_edition(format)}"\
                "#{render_localities(format)}"\
                "#{render_update(format)}#{render_translation(format)}"
      result = render_addendum(result, format)

      return result.gsub(" ", ".") if format == :mr

      result
    end

    def to_json(*args)
      result = {
        styles: {
          short: to_s(:short),
          abbrev: to_s(:abbrev),
          long: to_s(:long),
          mr: to_s(:mr),
        }
      }

      instance_variables.each do |var|
        val = instance_variable_get(var)
        result[var.to_s.gsub('@', '')] = val unless val.nil?
      end
      result.to_json(*args)
    end

    def render_serie(format)
      if serie.to_s(format).include?(publisher.to_s(format))
        return serie.to_s(format)
      end

      "#{publisher.to_s(format)} #{serie.to_s(format)}"
    end

    def render_part(format)
      result = ""
      result += "#{VOLUME_DESC[format]}#{volume}" unless volume.nil?
      result += "#{PART_DESC[format]}#{part}" unless part.nil?
      result
    end

    def render_edition(format)
      result = ""

      result += "#{EDITION_DESC[format]}#{edition.to_s}" unless edition.nil?
      result += "#{REVISION_DESC[format]}#{revision.to_s}" if revision
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result
    end

    def render_localities(format)
      result = ""
      result += "#{SUPPLEMENT_DESC[format]}#{supplement}" unless supplement.nil?
      result += "#{SECTION_DESC[format]}#{section}" unless section.nil?
      result += "#{APPENDIX_DESC[format]}" unless appendix.nil?
      result += "#{ERRATA_DESC[format]}" unless errata.nil?
      result += INDEX_DESC[format] unless index.nil?
      result += INSERT_DESC[format] unless insert.nil?

      result
    end

    def render_update(format)
      return "" if update_year.nil?

      if update_number.match?(/\d+/)
        update_text = update_number
        update_text += "-#{update_year}" if update_year && !update_year.empty?
      else
        update_text = "1"
      end

      case format
      when :long
        " Update #{update_text}"
      when :abbrev
        " Upd. #{update_text}"
      when :short
        "/Upd#{update_text}"
      when :mr
        ".u#{update_text}"
      end
    end

    def render_translation(format)
      return "" if translation.nil?

      case format
      when :long, :abbrev
        " (#{translation.upcase})"
      when :mr
        ".#{translation}"
      when :short
        "(#{translation})"
      end
    end

    def render_addendum(input, format)
      return input unless addendum

      case format
      when :long
        "Addendum to #{input}"
      when :abbrev
        "Add. to #{input}"
      when :short
        "#{input} Add."
      when :mr
        "#{input}.add-1"
      end
    end
  end
end
