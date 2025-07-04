import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "monthlyButton",
    "yearlyButton",
    "monthlyPrice",    // These are collections for each card
    "yearlyPrice",     // These are collections for each card
    "monthlyButtonForm", // These are collections for each card
    "yearlyButtonForm"   // These are collections for each card
  ]

  // Define styling classes for different plan types when they are current
  PLAN_STYLES = {
    essentials: {
      current: ['border-2', 'border-green-500', 'dark:border-green-600', 'ring-2', 'ring-green-500', 'dark:ring-green-600', 'opacity-75'],
    },
    pro: {
      current: ['border-4', 'border-green-500', 'dark:border-green-600', 'ring-4', 'ring-green-500', 'dark:ring-green-600', 'opacity-75'],
    },
    business: {
      current: ['border-2', 'border-green-500', 'dark:border-green-600', 'ring-2', 'ring-green-500', 'dark:ring-green-600', 'opacity-75'],
    }
  }

  // Default border for non-current cards
  DEFAULT_BORDER_CLASSES = ['border', 'border-gray-200', 'dark:border-gray-700'];
  // Special border for Pro card when it's "most popular" but not the active subscription
  MOST_POPULAR_PRO_BORDER_CLASSES = ['border-2', 'border-green-500', 'dark:border-green-600'];


  connect() {
    this.showMonthly(); // Set initial state, which also calls updateAllCardStyles
  }

  showMonthly() {
    this._setActiveButton(this.monthlyButtonTarget, this.yearlyButtonTarget);
    this._togglePriceAndFormVisibility("monthly");
    this.updateAllCardStyles("monthly");
  }

  showYearly() {
    this._setActiveButton(this.yearlyButtonTarget, this.monthlyButtonTarget);
    this._togglePriceAndFormVisibility("yearly");
    this.updateAllCardStyles("yearly");
  }

  _setActiveButton(activeButton, inactiveButton) {
    activeButton.classList.remove('text-gray-700', 'dark:text-gray-300'); // Assuming default is gray
    activeButton.classList.add('text-white', 'bg-green-600', 'dark:bg-green-700', 'shadow');
    
    inactiveButton.classList.remove('text-white', 'bg-green-600', 'dark:bg-green-700', 'shadow');
    inactiveButton.classList.add('text-gray-700', 'dark:text-gray-300'); // Reset to default non-active
  }

  _togglePriceAndFormVisibility(typeToShow) {
    this.monthlyPriceTargets.forEach(el => el.classList.toggle('hidden', typeToShow !== 'monthly'));
    this.yearlyPriceTargets.forEach(el => el.classList.toggle('hidden', typeToShow !== 'yearly'));
    this.monthlyButtonFormTargets.forEach(el => el.classList.toggle('hidden', typeToShow !== 'monthly'));
    this.yearlyButtonFormTargets.forEach(el => el.classList.toggle('hidden', typeToShow !== 'yearly'));
  }

  updateAllCardStyles(activeToggleType) { // activeToggleType is 'monthly' or 'yearly'
    const cards = this.element.querySelectorAll('[data-pricing-toggle-card]');

    cards.forEach(card => {
      const planName = card.dataset.planName; // 'essentials', 'pro', 'business'
      const isCurrentMonthly = card.dataset.isCurrentMonthly === 'true';
      const isCurrentYearly = card.dataset.isCurrentYearly === 'true';
      
      const stylesForThisPlan = this.PLAN_STYLES[planName];
      if (!stylesForThisPlan) return; 

      const currentPlanStylingClasses = stylesForThisPlan.current;

      const monthlyBadge = card.querySelector('[data-pricing-badge="monthly"]');
      const yearlyBadge = card.querySelector('[data-pricing-badge="yearly"]');
      const mostPopularBadge = (planName === 'pro') ? card.querySelector('[data-most-popular-badge]') : null;

      // 1. Reset all potentially conflicting styles and badges for this card
      currentPlanStylingClasses.forEach(cls => card.classList.remove(cls));
      this.DEFAULT_BORDER_CLASSES.forEach(cls => card.classList.remove(cls));
      if (planName === 'pro') {
        this.MOST_POPULAR_PRO_BORDER_CLASSES.forEach(cls => card.classList.remove(cls));
      }
      // Opacity is part of currentPlanStylingClasses, so it's removed above. Ensure no lingering opacity.
      card.classList.remove('opacity-75');


      if (monthlyBadge) monthlyBadge.classList.add('hidden');
      if (yearlyBadge) yearlyBadge.classList.add('hidden');
      if (mostPopularBadge) mostPopularBadge.classList.add('hidden'); // Hide initially, show if conditions met

      let isThisCardTheCurrentActivePlanForTheToggle = false;
      let badgeToMakeVisible = null;

      if (activeToggleType === 'monthly' && isCurrentMonthly) {
        isThisCardTheCurrentActivePlanForTheToggle = true;
        badgeToMakeVisible = monthlyBadge;
      } else if (activeToggleType === 'yearly' && isCurrentYearly) {
        isThisCardTheCurrentActivePlanForTheToggle = true;
        badgeToMakeVisible = yearlyBadge;
      }

      // 2. Apply new styling based on whether it's the active plan for the current toggle
      if (isThisCardTheCurrentActivePlanForTheToggle) {
        currentPlanStylingClasses.forEach(cls => card.classList.add(cls)); // Applies border, ring, opacity
        if (badgeToMakeVisible) badgeToMakeVisible.classList.remove('hidden');
        // "Most Popular" badge on Pro remains hidden if Pro is the "Current Plan"
      } else {
        // This card is NOT the "Current Plan" for the current toggle. Apply default or "Most Popular" styling.
        card.classList.remove('opacity-75'); // Ensure no opacity if not current

        if (planName === 'pro') {
          if (mostPopularBadge) mostPopularBadge.classList.remove('hidden'); // Show "Most Popular" badge

          const isProTheUsersActualSubscription = card.dataset.isProActiveSubscription === 'true';
          if (!isProTheUsersActualSubscription) {
            // Pro is not the user's actual plan (user is on Essentials/Business or no sub at all)
            // So, Pro gets its "Most Popular" border.
            this.MOST_POPULAR_PRO_BORDER_CLASSES.forEach(cls => card.classList.add(cls));
          } else {
            // User IS subscribed to Pro, but this toggle view makes it non-current
            // (e.g., user on Pro Monthly, toggle is Yearly). Pro gets default border.
            this.DEFAULT_BORDER_CLASSES.forEach(cls => card.classList.add(cls));
          }
        } else { 
          // Essentials or Business, and not the "Current Plan" for this toggle. Gets default border.
          this.DEFAULT_BORDER_CLASSES.forEach(cls => card.classList.add(cls));
        }
      }
    });
  }
}