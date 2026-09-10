module PublicContent
  class TestimonialsQuery
    PUBLIC_COLUMNS = %i[id author_name relationship quote_ar quote_en public_display_order].freeze
    HOME_LIMIT = 3

    def homepage = PublicTestimonial.publicly_visible.public_ordered.select(PUBLIC_COLUMNS).limit(HOME_LIMIT)
  end
end
