module ApplicationHelper
  include Pagy::Frontend

  def render_load_more(pagy)
    render "shared/load_more", pagy: pagy
  end
  
  # returns full title if present, else returns base title
  def full_title(page_title="")
    base_title = "Inventorify"
    if page_title.blank?
        base_title
    else
        "#{page_title} | #{base_title}"
    end
  end

  def render_turbo_stream_flash_messages
    turbo_stream.prepend "flash", partial: "shared/flash"
  end

  def delete_modal(resource, path)
    render partial: 'shared/delete_modal', locals: {
      resource: resource,
      path: path
    }
  end

  # In your ApplicationHelper
  def classes_for_flash(flash_type)
    case flash_type.to_sym
    when :notice, :success
      "bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100"
    when :alert, :error
      "bg-red-100 text-red-800 dark:bg-red-800 dark:text-red-100"
    when :warning
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-100"
    when :info
      "bg-blue-100 text-blue-800 dark:bg-blue-800 dark:text-blue-100"
    else
      "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-100"
    end
  end
end
