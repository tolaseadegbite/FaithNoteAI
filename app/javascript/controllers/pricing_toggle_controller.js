import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "monthlyButton", "yearlyButton", "monthlyPrice", "yearlyPrice", "discountBadge" ]

  connect() {
    this.showMonthly(); // Set initial state
  }

  showMonthly() {
    this.monthlyButtonTarget.classList.add('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.monthlyButtonTarget.classList.remove('text-gray-700', 'dark:text-gray-200');
    this.yearlyButtonTarget.classList.remove('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.yearlyButtonTarget.classList.add('text-gray-700', 'dark:text-gray-200');

    this.monthlyPriceTargets.forEach(el => el.classList.remove('hidden'));
    this.yearlyPriceTargets.forEach(el => el.classList.add('hidden'));

    // Assuming discount badge is only for annual
    if (this.hasDiscountBadgeTarget) {
       this.discountBadgeTarget.classList.remove('hidden');
    }
  }

  showYearly() {
    this.yearlyButtonTarget.classList.add('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.yearlyButtonTarget.classList.remove('text-gray-700', 'dark:text-gray-200');
    this.monthlyButtonTarget.classList.remove('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.monthlyButtonTarget.classList.add('text-gray-700', 'dark:text-gray-200');

    this.monthlyPriceTargets.forEach(el => el.classList.add('hidden'));
    this.yearlyPriceTargets.forEach(el => el.classList.remove('hidden'));

     // Assuming discount badge is only for annual
    if (this.hasDiscountBadgeTarget) {
       this.discountBadgeTarget.classList.remove('hidden');
    }
  }
}
