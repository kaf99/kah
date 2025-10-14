Rails.application.config.to_prepare do
  if defined?(Spree::Search::Base)
    require_dependency Rails.root.join('app/models/spree/search/base_decorator')
    Spree::Search::Base.prepend(Spree::Search::BaseDecorator)
  end
end