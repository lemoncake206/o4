class SecondaryCategory < Tag
  validates :canonical, presence: { message: "^Only canonical secondary category tags are allowed." }

  NAME = ArchiveConfig.SCATEGORY_SCATEGORY_NAME

end