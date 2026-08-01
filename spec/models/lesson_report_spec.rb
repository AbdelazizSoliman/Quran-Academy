require "rails_helper"

RSpec.describe LessonReport do
  it "enforces one immutable report per lesson" do
    report = create(:lesson_report)
    expect(report.public_id).to match(/\ALRP-/)
    expect(build(:lesson_report, scheduled_lesson: report.scheduled_lesson)).not_to be_valid
    expect { report.update!(scheduled_lesson_id: create(:scheduled_lesson).id) }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "validates student entry ownership and controlled catalogs" do
    entry = create(:lesson_student_report)
    expect(entry.public_id).to match(/\ALSR-/)
    entry.tajweed_topics = %w[madd invented]
    expect(entry).not_to be_valid
  end

  it "prevents duplicate student entries" do
    entry = create(:lesson_student_report)
    duplicate = build(:lesson_student_report, lesson_report: entry.lesson_report,
                                              scheduled_lesson_enrollment: entry.scheduled_lesson_enrollment)
    expect(duplicate).not_to be_valid
  end

  it "uses honest manual communication states and immutable identity" do
    log = create(:communication_log)
    expect(log.public_id).to match(/\ACOM-/)
    expect(log).to be_prepared
    expect(log).not_to be_confirmed_sent
  end

  it "restricts report deletion when audit history exists" do
    report = create(:lesson_report)
    create(:lesson_report_event, lesson_report: report)
    expect { report.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
  end
end
