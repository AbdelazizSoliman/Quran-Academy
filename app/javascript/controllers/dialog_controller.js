import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "content"]

  open() {
    this.previouslyFocused = document.activeElement
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
    this.previouslyFocused?.focus()
  }

  cancel(event) {
    event.preventDefault()
    this.close()
  }

  backdropClose(event) {
    if (!this.contentTarget.contains(event.target)) this.close()
  }
}
