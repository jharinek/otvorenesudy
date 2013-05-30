module DecreePagesHelper
  def link_to_decree_page(decree, page, title, options = {})
    link = "#{decree_path(decree)}#document/1/page/#{page}"

    link_to title, link, options
  end
end
