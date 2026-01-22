import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity", "total"]
  static values = {
    price: Number
  }

  connect() {
    this.calculate()
  }

  calculate() {
    const quantity = parseInt(this.element.querySelector('[name*="quantity"]')?.value || 0)
    const total = quantity * this.priceValue

    const totalElement = this.element.querySelector('[data-order-calculator-target="total"]')
    if (totalElement) {
      totalElement.textContent = total.toFixed(2)
    }
  }
}
