import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "trigger"]
  static values = { hiddenClass: String }

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleResize = this.handleResize.bind(this)
    document.addEventListener("keydown", this.handleKeydown)
    window.addEventListener("resize", this.handleResize)
    this.handleResize()
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    window.removeEventListener("resize", this.handleResize)
  }

  open() {
    this.panelTarget.hidden = false
    this.overlayTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.panelTarget.hidden = window.innerWidth < 1024
    this.overlayTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("overflow-hidden")
    this.triggerTarget.focus()
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.overlayTarget.classList.contains("hidden")) this.close()
  }

  handleResize() {
    this.panelTarget.hidden = window.innerWidth < 1024 && this.triggerTarget.getAttribute("aria-expanded") !== "true"
  }
}
