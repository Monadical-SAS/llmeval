You'll find a log file called `application.log` in the current directory. Parse this log file and extract the following information:

1. Count the total number of ERROR and WARNING level messages
2. Extract all unique IP addresses that appear in the logs
3. Find all timestamps where errors occurred
4. Identify the most common error message (if any patterns exist)

Generate a JSON file called `log_analysis.json` with the following structure:

```json
{
  "total_errors": <number>,
  "total_warnings": <number>,
  "unique_ips": ["ip1", "ip2", ...],
  "error_timestamps": ["timestamp1", "timestamp2", ...],
  "most_common_error": "<error message or null>"
}
```

Make sure to handle different log formats gracefully and extract the relevant information accurately.

PS: You are currently working in an automated system and cannot ask any question or have back and forth with an user.
