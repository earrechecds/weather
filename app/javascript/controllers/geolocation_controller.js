import { Controller } from "@hotwired/stimulus"
import { fetchWithTurbo } from '../modules/utils/fetchWithTurbo';

const options = {
  enableHighAccuracy: true,
  maximumAge: 0
};

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.getLocation();
  }

  getLocation() {
    navigator.geolocation.getCurrentPosition(this.success.bind(this), this.error, options);
  }
  
  
  success(pos) {
    const crd = pos.coords;
    console.log(pos);
    fetchWithTurbo(`/query_by_position?lat=${crd.latitude}&long=${crd.longitude}`);
  }

  error(err) {
    console.warn(`ERROR(${err.code}): ${err.message}`);
  }
}
