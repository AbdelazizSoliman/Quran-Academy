import { Controller } from "@hotwired/stimulus"

// Manages the "مواعيد الحصص" dynamic, unlimited slot list on the student onboarding form,
// matching Madarak's real implementation: rows are added/removed freely (not fixed at 3), and
// the whole list is serialized into one hidden JSON field on every change.
export default class extends Controller {
  static targets = ["container", "hidden", "template"]

  connect() {
    if (this.containerTarget.children.length === 0) this.add()
    this.sync()
  }

  add() {
    const row = this.templateTarget.content.firstElementChild.cloneNode(true)
    this.containerTarget.appendChild(row)
    this.sync()
  }

  remove(event) {
    const row = event.target.closest("[data-schedule-slots-row]")
    if (row) row.remove()
    this.sync()
  }

  sync() {
    const slots = Array.from(this.containerTarget.children).map((row) => ({
      weekday: row.querySelector('[data-slot-field="weekday"]').value,
      time: row.querySelector('[data-slot-field="time"]').value,
      duration: row.querySelector('[data-slot-field="duration"]').value,
      subject: row.querySelector('[data-slot-field="subject"]').value
    }))
    this.hiddenTarget.value = JSON.stringify(slots)
  }
}
