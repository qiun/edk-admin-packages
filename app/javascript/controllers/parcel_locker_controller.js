import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["code", "name", "address", "city", "postCode", "selected", "selectedName", "selectedAddress"]

  connect() {
    this.loadFurgonetkaScript()
  }

  loadFurgonetkaScript() {
    if (window.Furgonetka) {
      this.scriptLoaded = true
      return
    }

    const script = document.createElement('script')
    script.src = 'https://furgonetka.pl/js/dist/map/map.js'
    script.onload = () => {
      this.scriptLoaded = true
      console.log('Furgonetka Map script loaded')
    }
    script.onerror = () => {
      console.error('Failed to load Furgonetka Map script')
    }
    document.head.appendChild(script)
  }

  openMap(event) {
    event.preventDefault()

    if (!window.Furgonetka) {
      console.error('Furgonetka Map script not loaded yet')
      alert('Mapa paczkomatów jeszcze się ładuje. Spróbuj ponownie za chwilę.')
      return
    }

    try {
      new window.Furgonetka.Map({
        courierServices: ['inpost'],            // Tylko InPost
        type: 'parcel_machine',                 // Tylko paczkomaty
        pointTypesFilter: ['parcel_machine'],   // Filtr tylko na automaty
        callback: (params) => this.onPointSelected(params),
        zoom: 14,
      }).show()
    } catch (error) {
      console.error('Error opening Furgonetka Map:', error)
      alert('Błąd podczas otwierania mapy. Spróbuj odświeżyć stronę.')
    }
  }

  onPointSelected(params) {
    if (!params || !params.point) {
      console.error('No point data received')
      return
    }

    const { code, name, type, address } = params.point

    // Weryfikacja czy to paczkomat InPost
    const lockerType = (type || '').toLowerCase()
    if (lockerType !== 'inpost') {
      alert('Proszę wybrać paczkomat InPost')
      return
    }

    // Zapisz dane paczkomatu
    this.codeTarget.value = code || ''
    this.nameTarget.value = name || ''
    this.addressTarget.value = address?.street || address?.line2 || ''
    this.cityTarget.value = address?.city || ''
    this.postCodeTarget.value = address?.postCode || address?.post_code || ''

    // Pokaż wybrany paczkomat
    this.selectedTarget.classList.remove('hidden')
    this.selectedNameTarget.textContent = `${code} - ${name}`
    this.selectedAddressTarget.textContent = `${address?.city || ''}, ${address?.postCode || address?.post_code || ''}`

    console.log('Parcel locker selected:', { code, name, address })
  }
}
