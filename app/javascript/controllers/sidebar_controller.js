import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "trigger"]
  static values = { hiddenClass: String }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  open() {
    this.panelTarget.classList.remove(this.hiddenClassValue)
    this.overlayTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.classList.add(this.hiddenClassValue)
    this.overlayTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("overflow-hidden")
    this.triggerTarget.focus()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.overlayTarget.classList.contains("hidden")) this.close()
  }
}
