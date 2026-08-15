import { Controller } from "@hotwired/stimulus"

// Toggles the "Course Offering" vs "Student" fields on the admin new-lesson form based on which
// lesson type radio is selected, so only the fields relevant to the chosen path are shown.
export default class extends Controller {
  static targets = ["offering", "student"]

  toggle() {
    const direct = this.element.querySelector('input[name="scheduled_lesson[lesson_type]"]:checked')?.value === "direct_student"
    this.offeringTarget.hidden = direct
    this.studentTarget.hidden = !direct
  }
}
