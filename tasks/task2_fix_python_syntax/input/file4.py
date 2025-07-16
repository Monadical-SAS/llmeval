def process_list(items):
    result = []
    for item in items:
        if item % 2 == 0:
            result.append(item * 2)
        else:
            result.append(item + 1)
    return result

data = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
processed = process_list(data)
print("Original:", data
print("Processed:", processed)