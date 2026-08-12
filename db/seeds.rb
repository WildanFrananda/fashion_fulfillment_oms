# typed: false
# db/seeds.rb

puts "🌱 Seeding Fashion Fulfillment OMS demo database..."

# 1. Create Merchants
merchant1 = Merchant.find_or_create_by!(code: "BH-001") do |m|
  m.name = "Boutique Hijab Premium"
  m.api_key = "secret-api-key-merchant-1"
  m.cutoff_hour = 14
end

merchant2 = Merchant.find_or_create_by!(code: "GES-002") do |m|
  m.name = "Gamis Elegant Style"
  m.api_key = "secret-api-key-merchant-2"
  m.cutoff_hour = 15
end

puts "✅ Merchants created: #{merchant1.name}, #{merchant2.name}"

# 2. Create Staff Users
staff1 = StaffUser.find_or_create_by!(merchant: merchant1, email: "manager@boutiquehijab.com") do |u|
  u.name = "Budi Hendra"
  u.role = "Warehouse Lead Manager"
end

staff2 = StaffUser.find_or_create_by!(merchant: merchant2, email: "manager@gamiselegant.com") do |u|
  u.name = "Siti Nurhaliza"
  u.role = "Fulfillment Logistics Manager"
end

puts "✅ Staff Users created: #{staff1.name}, #{staff2.name}"

# 3. Create Orders for Merchant 1 (Boutique Hijab Premium)
today = Time.current

order1 = Order.find_or_create_by!(merchant: merchant1, order_number: "ORD-BH-1001") do |o|
  o.buyer_name = "Sarah Jane"
  o.buyer_phone = "081234567890"
  o.shipping_address = "124 Maple Street, Apt 4B, Brooklyn, NY 11201"
  o.status = "packing"
  o.total_amount = 450000.0
  o.same_day_cutoff_at = today - 1.hour # Overdue SLA
end

if order1.order_items.empty?
  order1.order_items.create!(sku: "BH-SLK-NVY", product_name: "Premium Silk Hijab (Navy)", quantity: 1, price: 350000.0, bin_location: "Rak A-01, Bin 12")
  order1.order_items.create!(sku: "HJB-PSH-BLK", product_name: "Hijab Pashmina Silk Black", quantity: 1, price: 100000.0, bin_location: "Rak A-01, Bin 13")
end

order2 = Order.find_or_create_by!(merchant: merchant1, order_number: "ORD-BH-1002") do |o|
  o.buyer_name = "Michael Chen"
  o.buyer_phone = "082345678901"
  o.shipping_address = "789 Pine Road, Suite 200, Seattle, WA 98101"
  o.status = "packed"
  o.total_amount = 280000.0
  o.same_day_cutoff_at = today + 30.minutes # Due Soon SLA
end

if order2.order_items.empty?
  order2.order_items.create!(sku: "BH-CTN-BLK", product_name: "Everyday Cotton Hijab (Black)", quantity: 2, price: 140000.0, bin_location: "Rak B-14, Bin 05")
end

order3 = Order.find_or_create_by!(merchant: merchant1, order_number: "ORD-BH-0998") do |o|
  o.buyer_name = "Emma Watson"
  o.buyer_phone = "083456789012"
  o.shipping_address = "456 Oak Lane, Austin, TX 78701"
  o.status = "dispatched"
  o.total_amount = 520000.0
  o.same_day_cutoff_at = today + 4.hours # Due Today SLA
end

if order3.order_items.empty?
  order3.order_items.create!(sku: "BH-CHF-EMR", product_name: "Chiffon Evening Wrap (Emerald)", quantity: 1, price: 520000.0, bin_location: "Rak C-02, Bin 08")
end

order3_b = Order.find_or_create_by!(merchant: merchant1, order_number: "ORD-BH-1004") do |o|
  o.buyer_name = "Rina Anggraini"
  o.buyer_phone = "081987654321"
  o.shipping_address = "Jl. Cikini Raya No. 99, Jakarta Pusat"
  o.status = "received"
  o.total_amount = 320000.0
  o.same_day_cutoff_at = today + 2.hours
end

if order3_b.order_items.empty?
  order3_b.order_items.create!(sku: "HJB-SLK-SLV", product_name: "Hijab Silk Silver Premium", quantity: 2, price: 160000.0, bin_location: "Rak A-02, Bin 01")
end

# 4. Create Orders for Merchant 2 (Gamis Elegant Style)
order4 = Order.find_or_create_by!(merchant: merchant2, order_number: "ORD-GES-2001") do |o|
  o.buyer_name = "Anisa Fitri"
  o.buyer_phone = "084567890123"
  o.shipping_address = "Jl. Malioboro No. 88, Yogyakarta"
  o.status = "in_transit"
  o.total_amount = 680000.0
  o.same_day_cutoff_at = today + 3.hours
end

if order4.order_items.empty?
  order4.order_items.create!(sku: "GMS-EMR-XL", product_name: "Gamis Velvet Emerald XL", quantity: 1, price: 680000.0, bin_location: "Rak D-05, Bin 01")
end

order5 = Order.find_or_create_by!(merchant: merchant2, order_number: "ORD-GES-2002") do |o|
  o.buyer_name = "Dewi Sartika"
  o.buyer_phone = "085678901234"
  o.shipping_address = "Jl. Pemuda No. 101, Surabaya"
  o.status = "delivered"
  o.total_amount = 390000.0
  o.same_day_cutoff_at = today - 2.hours
end

if order5.order_items.empty?
  order5.order_items.create!(sku: "KKO-MDR-M", product_name: "Koko Modern Slim Fit M", quantity: 1, price: 390000.0, bin_location: "Rak E-01, Bin 10")
end

# 5. Create Shipping Labels & Returns
ShippingLabel.find_or_create_by!(order: order3) do |l|
  l.awb_number = "TRK-998-XYZ"
  l.pdf_url = "/labels/TRK-998-XYZ.pdf"
  l.reprint_count = 1
end

Return.find_or_create_by!(merchant: merchant2, order: order5) do |r|
  r.reason = "Size too large, request exchange to M"
  r.status = "requested"
end

puts "🎉 Database successfully seeded with StaffUsers!"
