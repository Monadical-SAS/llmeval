# Deterministic Money Distribution on a Directed Graph

You must compute the final money distribution on a directed graph following precise rules.

## Graph Structure

**CONDUCTOR nodes**: C1 through C10
**BENEFICIARY nodes**: B1 through B10 (each Ci has exactly one Bi)

**Directed edges between CONDUCTORs**:
```
C1 --> C2
C2 --> C3
C3 --> C4
C4 --> C2
C4 --> C5
C5 --> C6
C6 --> C7
C7 --> C5
C7 --> C8
C8 --> C9
C9 --> C10
C10 --> C6
```

## Initial Conditions

Solve for **three scenarios**:

1. **Scenario A**: C4 receives **5 cents**. All other nodes start with 0 cents.
2. **Scenario B**: C4 receives **50 cents**. All other nodes start with 0 cents.
3. **Scenario C**: C4 receives **100 cents**. All other nodes start with 0 cents.

## Distribution Rules

When a CONDUCTOR Ci receives N > 0 cents, it distributes ALL N cents in a single step to:
- Its BENEFICIARY Bi
- All CONDUCTORs it has outgoing edges to

**Split Rule**:
1. Divide money equally among all participants
2. Remaining cents (from integer division) are distributed one by one
3. **Tie-break order**: BENEFICIARY first, then CONDUCTORs alphabetically (C1 < C2 < ... < C10)

**Example**: 8 cents split among [B4, C2, C5]:
- 8 / 3 = 2 each, remainder = 2
- Distribution order: B4, C2, C5
- Final: B4=3, C2=3, C5=2

## Recursion

Any CONDUCTOR receiving positive money repeats the same distribution.
BENEFICIARY nodes absorb money and never redistribute.

## Termination

Process ends when no CONDUCTOR holds positive money.

## Your Task

Compute the final amount held by each BENEFICIARY after the process terminates, for all three scenarios.

## Required Output

Create three files:

**`result_5.json`** (for Scenario A - 5 cents):
```json
{
  "B1": <cents>,
  "B2": <cents>,
  "B3": <cents>,
  "B4": <cents>,
  "B5": <cents>,
  "B6": <cents>,
  "B7": <cents>,
  "B8": <cents>,
  "B9": <cents>,
  "B10": <cents>
}
```

**`result_50.json`** (for Scenario B - 50 cents):
```json
{
  "B1": <cents>,
  "B2": <cents>,
  "B3": <cents>,
  "B4": <cents>,
  "B5": <cents>,
  "B6": <cents>,
  "B7": <cents>,
  "B8": <cents>,
  "B9": <cents>,
  "B10": <cents>
}
```

**`result_100.json`** (for Scenario C - 100 cents):
```json
{
  "B1": <cents>,
  "B2": <cents>,
  "B3": <cents>,
  "B4": <cents>,
  "B5": <cents>,
  "B6": <cents>,
  "B7": <cents>,
  "B8": <cents>,
  "B9": <cents>,
  "B10": <cents>
}
```

PS: You are currently working in an automated system and cannot ask any question or have back and forth with a user.
