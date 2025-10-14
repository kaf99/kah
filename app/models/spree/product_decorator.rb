# frozen_string_literal: true

module Spree
  module ProductDecorator
    def self.prepended(base)
      base.ransacker :tag_names, type: :string do
        Arel.sql(<<~SQL.squish)
          (
            SELECT STRING_AGG(LOWER(tags.name), ',')
            FROM tags
            INNER JOIN taggings
              ON taggings.taggable_id = spree_products.id
             AND taggings.taggable_type = 'Spree::Product'
            INNER JOIN tags
              ON tags.id = taggings.tag_id
          )
        SQL
      end
    end
  end
end

Spree::Product.prepend(Spree::ProductDecorator)
