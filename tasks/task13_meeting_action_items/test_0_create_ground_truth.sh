#!/bin/bash
# Test 0: Create ground truth JSON files for validation
set -e

echo "Test 0: Creating ground truth files..."

# Create ground_truth directory
mkdir -p ground_truth

# Create 1.json - Michal has 1 action item
cat > ground_truth/1.json << 'EOF'
{
  "action_items": [
    {
      "action_item": "Ensure comprehensive data indexing from the contact database, including enrichment data",
      "deadline": null
    }
  ]
}
EOF

# Create 2.json - Michal has no action items
cat > ground_truth/2.json << 'EOF'
{
  "action_items": []
}
EOF

# Create 3.json - Michal has no action items
cat > ground_truth/3.json << 'EOF'
{
  "action_items": []
}
EOF

# Create 4.json - Michal has 1 action item
cat > ground_truth/4.json << 'EOF'
{
  "action_items": [
    {
      "action_item": "Add contacts to ContactDB and ensure they can be ingested into the data index (search index)",
      "deadline": null
    }
  ]
}
EOF

# Create 5.json - Michal has no action items
cat > ground_truth/5.json << 'EOF'
{
  "action_items": []
}
EOF

echo "✓ Created ground_truth/1.json (1 action item for Michal)"
echo "✓ Created ground_truth/2.json (0 action items for Michal)"
echo "✓ Created ground_truth/3.json (0 action items for Michal)"
echo "✓ Created ground_truth/4.json (1 action item for Michal)"
echo "✓ Created ground_truth/5.json (0 action items for Michal)"

echo ""
echo "SUCCESS: Ground truth files created successfully!"
