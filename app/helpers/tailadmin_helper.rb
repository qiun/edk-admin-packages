module TailadminHelper
  # Klasa dla pola input
  def tailadmin_input_class
    "w-full rounded-lg border border-stroke bg-transparent py-3 px-4 outline-none focus:border-primary dark:border-stroke-dark dark:bg-boxdark dark:text-white"
  end

  # Klasa dla przycisku primary
  def tailadmin_btn_primary_class
    "inline-flex items-center justify-center rounded-lg bg-primary px-6 py-3 font-medium text-white hover:bg-primary-dark transition"
  end

  # Klasa dla przycisku secondary
  def tailadmin_btn_secondary_class
    "inline-flex items-center justify-center rounded-lg border border-stroke bg-transparent px-6 py-3 font-medium text-gray-900 hover:bg-gray-50 transition dark:border-stroke-dark dark:text-white dark:hover:bg-meta-4"
  end

  # Klasa dla badge status
  def tailadmin_badge_class(status)
    case status.to_s
    when 'active', 'delivered', 'paid'
      "inline-flex rounded-full bg-success/10 px-3 py-1 text-sm font-medium text-success"
    when 'pending', 'draft'
      "inline-flex rounded-full bg-warning/10 px-3 py-1 text-sm font-medium text-warning"
    when 'cancelled', 'closed', 'unpaid'
      "inline-flex rounded-full bg-danger/10 px-3 py-1 text-sm font-medium text-danger"
    else
      "inline-flex rounded-full bg-gray-100 px-3 py-1 text-sm font-medium text-gray-600"
    end
  end
end
