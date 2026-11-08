# Shared methods for collection, bookmarkable, and work queries
module TaggableQuery

  def filter_ids
    return @filter_ids if @filter_ids.present?
    @filter_ids = options[:filter_ids] || []
    %w(fandom rating archive_warning category secondary_category character alpha_character beta_character omega_character relationship freeform).each do |tag_type|
      if options["#{tag_type}_ids".to_sym].present?
        ids = options["#{tag_type}_ids".to_sym]
        @filter_ids += ids.is_a?(Array) ? ids : [ids]
      end
    end
    @filter_ids += parsed_included_tags[:ids]
    @filter_ids = @filter_ids.uniq
  end

  def exclusion_ids
    return @exclusion_ids if @exclusion_ids.present?
    return if options[:excluded_tag_names].blank? && options[:excluded_tag_ids].blank?

    ids = options[:excluded_tag_ids] || []
    ids += parsed_excluded_tags[:ids]
    @exclusion_ids = ids.uniq.compact
  end

  # Returns a list of tag names that should be included in all results. Only
  # returns the ones that aren't in the database, because the ones that are in
  # the database will be covered by the filter_ids function.
  def included_tag_names
    parsed_included_tags[:missing]
  end

  # Returns parse_named_tags of all of the fields used to include tag names.
  def parsed_included_tags
    @parsed_included_tags ||= parse_named_tags(
      %i[fandom_names character_names alpha_character_names beta_character_names omega_character_names relationship_names freeform_names
         other_tag_names]
    )
  end

  # Returns a list of tag names that should be excluded from all results. Only
  # returns the ones that aren't in the database, because the ones that are in
  # the database will be covered by the exclusion_ids function.
  def excluded_tag_names
    parsed_excluded_tags[:missing]
  end

  # Returns parse_named_tags of all of the fields used to exclude tag names.
  def parsed_excluded_tags
    @parsed_excluded_tags ||= parse_named_tags(%i[excluded_tag_names])
  end

  # Uses the database to look up all of the tag names listed in the passed-in
  # fields. Returns a hash with the following format:
  #   {
  #     ids: [1, 2, 3],
  #     missing: ["missing tag name", "other missing"]
  #   }
  def parse_named_tags(fields)
    ids = []
    missing = []
  
    fields.each do |field|
      names = all_tag_names([field])
      next if names.blank?
  
      scope = case field
              when :character_names
                Tag.where(type: %w[
                  Character AlphaCharacter BetaCharacter OmegaCharacter
                ])
              when :alpha_character_names
                Tag.where(type: "AlphaCharacter")
              when :beta_character_names
                Tag.where(type: "BetaCharacter")
              when :omega_character_names
                Tag.where(type: "OmegaCharacter")
              else
                Tag.all
              end
  
      found = scope.where(name: names).pluck(:id, :name)
  
      ids.concat(found.map(&:first))
      missing.concat(names - found.map(&:second))
    end
  
    {
      ids: ids.uniq,
      missing: missing.uniq
    }
  end
  # Parse the options for each of the passed-in fields, treating each one as a
  # comma-separated list of tags. Returns the list of all tags, with blank and
  # duplicate tags removed.
  def all_tag_names(fields)
    fields.flat_map do |field|
      next if options[field].blank?
      options[field].split(",").map(&:squish)
    end.reject(&:blank?).uniq
  end
end
