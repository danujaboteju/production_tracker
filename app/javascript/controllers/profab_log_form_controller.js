import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["workType", "prodField", "otherField"]

  connect() {
    this.toggle()
  }

  toggle() {
    const selectedType = this.workTypeTargets.find((input) => input.checked)?.value || "PROD"
    const prodSelected = selectedType === "PROD"

    this.prodFieldTargets.forEach((field) => field.classList.toggle("hidden", !prodSelected))
    this.otherFieldTargets.forEach((field) => field.classList.toggle("hidden", prodSelected))
  }
}
