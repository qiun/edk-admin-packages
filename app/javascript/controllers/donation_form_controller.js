import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "quantity", "total", "wantGift", "giftSection",
    "lockerCode", "lockerName", "lockerAddress", "lockerCity", "lockerPostCode",
    "selectedLocker", "submitButton"
  ]

  static values = {
    pricePerUnit: { type: Number, default: 50 }
  }

  connect() {
    this.loadFurgonetkaScript()
    this.updateTotal()
  }

  loadFurgonetkaScript() {
    if (window.Furgonetka) {
      this.scriptLoaded = true
      return
    }

    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => { this.scriptLoaded = true }
    script.onerror = () => { console.error('Failed to load Furgonetka map script') }
    document.head.appendChild(script)
  }

  updateTotal() {
    if (!this.hasQuantityTarget || !this.hasTotalTarget) return
    
    const quantity = parseInt(this.quantityTarget.value) || 1
    const total = quantity * this.pricePerUnitValue
    this.totalTarget.textContent = total
  }

  toggleGiftSection() {
    if (!this.hasWantGiftTarget || !this.hasGiftSectionTarget) return
    
    const isChecked = this.wantGiftTarget.checked
    
    if (isChecked) {
      this.giftSectionTarget.classList.remove('hidden')
    } else {
      this.giftSectionTarget.classList.add('hidden')
    }
  }

  openFurgonetkaMap() {
    if (!window.Furgonetka) {
      console.error('Furgonetka map script not loaded')
      alert('Mapa nie została jeszcze załadowana. Spróbuj ponownie za chwilę.')
      return
    }

    try {
      new window.Furgonetka.Map({
        courierServices: ['inpost'],
        type: 'parcel_machine',
        pointTypesFilter: ['parcel_machine'],
        callback: (params) => this.onPointSelected(params),
        zoom: 14,
      }).show()
    } catch (error) {
      console.error('Error opening Furgonetka map:', error)
    }
  }

  onPointSelected(params) {
    if (!params || !params.point) return

    const { code, name, type, address, pointType } = params.point

    // Verify it's an InPost parcel locker
    if ((pointType && pointType !== 'parcel_machine') ||
        type.toLowerCase() !== 'inpost') {
      alert('Proszę wybrać paczkomat InPost.')
      return
    }

    // Set hidden field values
    if (this.hasLockerCodeTarget) this.lockerCodeTarget.value = code
    if (this.hasLockerNameTarget) this.lockerNameTarget.value = name
    if (this.hasLockerAddressTarget) this.lockerAddressTarget.value = address?.street || ''
    if (this.hasLockerCityTarget) this.lockerCityTarget.value = address?.city || ''
    if (this.hasLockerPostCodeTarget) this.lockerPostCodeTarget.value = address?.postCode || address?.post_code || ''

    // Update displayed selection
    if (this.hasSelectedLockerTarget) {
      this.selectedLockerTarget.innerHTML = `
        <div class="p-4 border border-green-400 rounded-lg bg-green-50">
          <p class="text-sm font-semibold text-gray-900">
            ${code} - ${name}
          </p>
          <p class="text-sm text-gray-600">
            ${address?.city || ''}, ${address?.postCode || address?.post_code || ''}
          </p>
        </div>
      `
    }
  }

  handleSubmit(event) {
    // Validate gift section if gift is wanted
    if (this.hasWantGiftTarget && this.wantGiftTarget.checked) {
      if (this.hasLockerCodeTarget && !this.lockerCodeTarget.value) {
        event.preventDefault()
        alert('Proszę wybrać paczkomat.')
        return false
      }
    }
  }
}
