# Configuration File Merger

Merge two JSON configuration files (`base.json` and `override.json`) into `merged.json`.

## Merge Rules

1. **Objects**: Deep merge recursively
   - Keep all keys from base that aren't in override
   - Override values replace base values for matching keys
   - Nested objects merge recursively at all levels

2. **Arrays**: Complete replacement (not concatenation)
   - Override arrays completely replace base arrays
   - Array order should be preserved exactly as in override

3. **Primitives**: Override wins
   - Strings, numbers, booleans from override replace base
   - Type changes are allowed (e.g., number → string)

4. **Null handling**: `null` in override REMOVES the key entirely
   - Works recursively in nested objects
   - Example: `{"a": {"b": null}}` removes key `b` from nested object `a`
   - Top-level null values remove top-level keys

## Example

Base: `{"server": {"port": 3000, "host": "localhost"}, "remove": "me"}`
Override: `{"server": {"port": 8080}, "remove": null}`
Result: `{"server": {"port": 8080, "host": "localhost"}}`

Note: `server.host` preserved (deep merge), `remove` deleted (null), `server.port` overridden

PS: You are currently working in an automated system and cannot ask any question or have back and forth with an user.
