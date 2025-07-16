import json

def save_config(filename, config):
    with open(filename, 'w') as f:
        json.dump(config, f, indent=4)

def load_config(filename):
    try:
        with open(filename, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {}

config = {
    "name": "MyApp",
    "version": "1.0.0",
    "debug": True
}

save_config("config.json", config)
loaded = load_config("config.json")
print(f"Loaded config: {loaded}")
print("Configuration saved and loaded successfully!"