import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "menu", "item"]

  connect() {
    this.outsideClick = this.outsideClick.bind(this)
    this.escape = this.escape.bind(this)
    document.addEventListener("click", this.outsideClick)
    document.addEventListener("keydown", this.escape)
  }

  disconnect() {
    document.removeEventListener("click", this.outsideClick)
    document.removeEventListener("keydown", this.escape)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.contains("hidden") ? this.open() : this.close()
  }

  open() {
    this.menuTarget.classList.remove("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.itemTargets[0]?.focus()
  }

  close({ restoreFocus = false } = {}) {
    this.menuTarget.classList.add("hidden")
    this.triggerTarget.setAttribute("aria-expanded", "false")
    if (restoreFocus) this.triggerTarget.focus()
  }

  navigate(event) {
    if (!["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return

    event.preventDefault()
    const current = this.itemTargets.indexOf(event.currentTarget)
    const next = event.key === "Home" ? 0 :
      event.key === "End" ? this.itemTargets.length - 1 :
        (current + (event.key === "ArrowDown" ? 1 : -1) + this.itemTargets.length) % this.itemTargets.length
    this.itemTargets[next].focus()
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  escape(event) {
    if (event.key === "Escape" && !this.menuTarget.classList.contains("hidden")) this.close({ restoreFocus: true })
  }
}
