#!/bin/bash
set -e

mkdir -p input
cd input

# Create base configuration
cat > base.json << 'EOF'
{
  "app_name": "MyApp",
  "version": "1.0.0",
  "server": {
    "port": 3000,
    "host": "localhost",
    "timeout": 30,
    "ssl": {
      "enabled": false
    }
  },
  "database": {
    "type": "postgres",
    "host": "localhost",
    "port": 5432,
    "pool": {
      "min": 2,
      "max": 10
    }
  },
  "features": ["auth", "api"],
  "debug": true,
  "remove_this": "should be deleted"
}
EOF

# Create override configuration
cat > override.json << 'EOF'
{
  "version": "2.0.0",
  "server": {
    "port": 8080,
    "ssl": {
      "enabled": true,
      "cert": "/etc/ssl/cert.pem"
    }
  },
  "database": {
    "pool": {
      "max": 20,
      "idle": 10000
    }
  },
  "features": ["auth", "api", "admin"],
  "debug": null,
  "remove_this": null,
  "new_setting": "added_value"
}
EOF

echo "✓ Created base.json and override.json"