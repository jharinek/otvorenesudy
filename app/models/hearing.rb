# encoding: utf-8

class Hearing < ActiveRecord::Base
  include Resource::Storage

  include Document::Indexable
  include Document::Suggestable
  include Document::Searchable

  attr_accessible :uri,
                  :case_number,
                  :file_number,
                  :date,
                  :room,
                  :special_type,
                  :commencement_date,
                  :selfjudge,
                  :note

  scope :at_court, lambda { |court| where court_id: court }

  scope :during_employment, lambda { |employment| where(court_id: employment.court).joins(:judgings).merge(Judging.of_judge(employment.judge)) }

  scope :upcoming, lambda { where("date >= ?", Time.now)  }
  scope :past, lambda { where("date < ?", Time.now) }

  belongs_to :proceeding

  belongs_to :court

  has_many :judgings, dependent: :destroy

  has_many :partial_judgings, dependent: :destroy

  has_many :judges, through: :judgings

  belongs_to :type,    class_name: :HearingType,    foreign_key: :hearing_type_id
  belongs_to :section, class_name: :HearingSection, foreign_key: :hearing_section_id
  belongs_to :subject, class_name: :HearingSubject, foreign_key: :hearing_subject_id
  belongs_to :form,    class_name: :HearingForm,    foreign_key: :hearing_form_id

  has_many :proposers,  dependent: :destroy
  has_many :opponents,  dependent: :destroy
  has_many :defendants, dependent: :destroy

  mapping do
    map     :id
    analyze :case_number
    analyze :file_number
    analyze :date,              type: 'date'
    analyze :room
    analyze :special_type
    analyze :commencement_date, type: 'date'
    analyze :type,              as: lambda { |h| h.section.value  if h.section        }
    analyze :subject,           as: lambda { |h| h.subject.value  if h.subject        }
    analyze :form,              as: lambda { |h| h.form.value     if h.form           }
    analyze :court,             as: lambda { |h| h.court.name     if court            }
    # TODO: consider naming in singular
    analyze :judges,            as: lambda { |h| h.judges.map(&:name).concat(h.partial_judgings.map(&:judge_name)) }
    analyze :proposers,         as: lambda { |h| h.proposers.map  { |p| p.name }      }
    analyze :opponents,         as: lambda { |h| h.opponents.map  { |o| o.name }      }
    analyze :defendants,        as: lambda { |h| h.defendants.map { |d| d.name }      }
  end

  facets do
    facet :judges, type: :terms
    facet :court,  type: :terms
    facet :date,   type: :date, interval: :month # using default alias for interval from DateFacet
    facet :historical, field: :date, type: :date, interval: :month, visible: false
  end

  storage :page, JusticeGovSk::Storage::HearingPage do |hearing|
    File.join hearing.type.name.to_s, JusticeGovSk::URL.url_to_path(hearing.uri, :html)
  end
end
