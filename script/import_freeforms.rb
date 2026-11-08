require "csv"

csv_path = Rails.root.join("Additional Tags Raw.csv")

unless File.exist?(csv_path)
  abort "ERROR: Could not find CSV file: #{csv_path}"
end

imported = 0
skipped = 0
failed = 0

puts "Starting canonical Freeform tag import..."
puts "Reading: #{csv_path}"
puts "----------------------------------------"

CSV.foreach(csv_path, headers: true, encoding: "bom|utf-8") do |row|
  name = row["name"].to_s.strip

  # Skip blank names and None
  if name.empty? || name.casecmp("None").zero?
    skipped += 1
    next
  end

  # Skip names containing Alpha, Beta, or Omega
  if name.match?(/\b(alpha|beta|omega)\b/i)
    skipped += 1
    next
  end

  # Skip tags that already exist
  if Tag.exists?(name: name)
    skipped += 1
    next
  end

  # Create canonical Freeform tag
  tag = Freeform.new(
    name: name,
    canonical: true
  )

  if tag.save
    imported += 1

    # Print each successful import immediately
    puts "Imported: #{name}"
    STDOUT.flush
  else
    failed += 1

    puts "FAILED: #{name}"
    puts "Reason: #{tag.errors.full_messages.join(', ')}"
    STDOUT.flush
  end
end

puts "----------------------------------------"
puts "IMPORT FINISHED"
puts "Successfully imported: #{imported}"
puts "Skipped: #{skipped}"
puts "Failed: #{failed}"
