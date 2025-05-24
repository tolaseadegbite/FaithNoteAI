import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "monthlyButton", "yearlyButton", "monthlyPrice", "yearlyPrice", "monthlyButtonForm", "yearlyButtonForm", "discountBadge", "intervalInput" ]

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

    this.monthlyButtonFormTargets.forEach(el => el.classList.remove('hidden'));
    this.yearlyButtonFormTargets.forEach(el => el.classList.add('hidden'));

    // Enable monthly interval inputs and disable yearly ones
    this.intervalInputTargets.forEach(input => {
      if (input.closest('[data-pricing-toggle-target="monthlyButtonForm"]')) {
        input.disabled = false;
      } else if (input.closest('[data-pricing-toggle-target="yearlyButtonForm"]')) {
        input.disabled = true;
      }
    });

    if (this.hasDiscountBadgeTarget) {
       this.discountBadgeTarget.classList.add('hidden'); // Hide discount badge for monthly
    }
  }

  showYearly() {
    this.yearlyButtonTarget.classList.add('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.yearlyButtonTarget.classList.remove('text-gray-700', 'dark:text-gray-200');
    this.monthlyButtonTarget.classList.remove('bg-green-600', 'dark:bg-green-700', 'text-white', 'shadow');
    this.monthlyButtonTarget.classList.add('text-gray-700', 'dark:text-gray-200');

    this.monthlyPriceTargets.forEach(el => el.classList.add('hidden'));
    this.yearlyPriceTargets.forEach(el => el.classList.remove('hidden'));

    this.monthlyButtonFormTargets.forEach(el => el.classList.add('hidden'));
    this.yearlyButtonFormTargets.forEach(el => el.classList.remove('hidden'));

    // Enable yearly interval inputs and disable monthly ones
    this.intervalInputTargets.forEach(input => {
      if (input.closest('[data-pricing-toggle-target="yearlyButtonForm"]')) {
        input.disabled = false;
      } else if (input.closest('[data-pricing-toggle-target="monthlyButtonForm"]')) {
        input.disabled = true;
      }
    });

    if (this.hasDiscountBadgeTarget) {
       this.discountBadgeTarget.classList.remove('hidden'); // Show discount badge for yearly
    }
  }
}
