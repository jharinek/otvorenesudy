# encoding: utf-8

module JusticeGovSk
  class Parser
    class Hearing < JusticeGovSk::Parser
      def case_number(document)
        find_value_by_label 'case number', document, 'Spisová značka' do |div|
          div.text.strip
        end
      end

      def file_number(document)
        find_value_by_label 'file number', document, 'IČS' do |div|
          div.text.strip
        end
      end

      def date(document)
        find_value_by_label 'date', document, 'Dátum pojednávania' do |div|
          normalize_datetime(div.text)
        end
      end

      def room(document)
        find_value_by_label 'room', document, 'Miestnosť' do |div|
          normalize_punctuation(div.text).to_s
        end
      end

      def note(document)
        find_value_by_label 'note', document, 'Poznámka' do |div|
          normalize_punctuation(div.text.gsub(/\A\s*\-+/, ''))
        end
      end

      def section(document)
        find_value_by_label 'section', document, 'Úsek' do |div|
          div.text.strip
        end
      end

      def court(document)
        find_value_by_label 'court', document, 'Súd' do |div|
          normalize_court_name(div.text)
        end
      end

      def judges(document)
        find_rows_by_group 'judges', document, 'Sudcovia', verbose: false do |divs|
          names = []

          divs.each_with_index do |div, i|
            if div[:class] == 'popiska' && div.text.blank? && divs[i + 1][:class] == 'hodnota'
              names << partition_person_name(divs[i + 1].text) if divs[i + 1].text =~ /[[:alnum:]]/
            end
          end

          names
        end
      end

      def subject(document)
        find_value_by_label 'subject', document, 'Predmet' do |div|
          normalize_punctuation(div.text.gsub(/\A\s*\-+/, '').strip.upcase_first)
        end
      end

      def form(document)
        find_value_by_label 'form', document, 'Forma úkonu' do |div|
          div.text.strip.upcase_first
        end
      end
    end
  end
end
