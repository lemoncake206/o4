require "csv"

csv_path = Rails.root.join("Fandom Tags Raw.csv")

unless File.exist?(csv_path)
  abort "ERROR: Fandom Tags Raw.csv was not found."
end

created = 0
skipped = 0
failed = []

CSV.foreach(csv_path, headers: true) do |row|
  name = row["name"].to_s.strip

  # Skip blank or invalid names
  if name.empty? || name.casecmp("None").zero?
    skipped += 1
    next
  end

  # Skip names that already exist in ANY tag category
  if Tag.exists?(name: name)
    skipped += 1
    next
  end

  # Create the fandom as a canonical Fandom tag
  fandom = Fandom.new(
    name: name,
    canonical: true
  )

  if fandom.save
    created += 1
  else
    failed << {
      name: name,
      errors: fandom.errors.full_messages
    }
  end
end

puts "--------------------------------"
puts "FANDOM IMPORT COMPLETE"
puts "Created: #{created}"
puts "Skipped: #{skipped}"
puts "Failed: #{failed.length}"
puts "--------------------------------"

failed.each do |entry|
  puts "#{entry[:name]}: #{entry[:errors].join(', ')}"
end