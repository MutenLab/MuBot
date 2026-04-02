#!/usr/bin/env python3
"""
Calculate optimal boss route using greedy nearest-neighbor approach.
At each step, go to the closest unvisited boss (comparing direct vs via entrance).

Usage:
    python3 optimizeBossRouteOnSanctuaryMap.py "1 3 5 7 9"
    python3 optimizeBossRouteOnSanctuaryMap.py --stdin

Output:
    Optimal route as space-separated boss numbers
"""

import sys

# Travel times from sanctuary2_bosses.sh config
TRAVEL_TIMES = {
    # From ENTRANCE
    ('ENTRANCE', 1): 9,
    ('ENTRANCE', 2): 19,
    ('ENTRANCE', 3): 30,
    ('ENTRANCE', 4): 40,
    ('ENTRANCE', 5): 49,
    ('ENTRANCE', 6): 48,
    ('ENTRANCE', 7): 24,
    ('ENTRANCE', 8): 30,
    ('ENTRANCE', 9): 38,
    ('ENTRANCE', 10): 47,
    ('ENTRANCE', 11): 57,
    ('ENTRANCE', 12): 68,
    # From BOSS_1
    (1, 2): 12,
    (1, 3): 24,
    (1, 4): 36,
    (1, 5): 66,
    (1, 6): 30,
    (1, 7): 28,
    (1, 8): 33,
    (1, 9): 43,
    (1, 10): 55,
    (1, 11): 68,
    (1, 12): 80,
    # From BOSS_2
    (2, 3): 12,
    (2, 4): 22,
    (2, 5): 36,
    (2, 6): 66,
    (2, 7): 40,
    (2, 8): 45,
    (2, 9): 67,
    (2, 10): 56,
    (2, 11): 81,
    (2, 12): 69,
    # From BOSS_3
    (3, 4): 12,
    (3, 5): 24,
    (3, 6): 54,
    (3, 7): 52,
    (3, 8): 57,
    (3, 9): 69,
    (3, 10): 81,
    (3, 11): 69,
    (3, 12): 51,
    # From BOSS_4
    (4, 5): 12,
    (4, 6): 42,
    (4, 7): 82,
    (4, 8): 69,
    (4, 9): 73,
    (4, 10): 69,
    (4, 11): 55,
    (4, 12): 40,
    # From BOSS_5
    (5, 6): 28,
    (5, 7): 60,
    (5, 8): 76,
    (5, 9): 69,
    (5, 10): 55,
    (5, 11): 45,
    (5, 12): 33,
    # From BOSS_6
    (6, 7): 25,
    (6, 8): 52,
    (6, 9): 63,
    (6, 10): 54,
    (6, 11): 42,
    (6, 12): 30,
    # From BOSS_7
    (7, 8): 28,
    (7, 9): 42,
    (7, 10): 54,
    (7, 11): 66,
    (7, 12): 78,
    # From BOSS_8
    (8, 9): 12,
    (8, 10): 24,
    (8, 11): 36,
    (8, 12): 48,
    # From BOSS_9
    (9, 10): 12,
    (9, 11): 22,
    (9, 12): 36,
    # From BOSS_10
    (10, 11): 12,
    (10, 12): 24,
    # From BOSS_11
    (11, 12): 12,
}

WIRE_SWITCH_TIME = 3


def get_direct_travel_time(from_loc, to_loc):
    """Get direct travel time (handles reverse lookup)."""
    if from_loc == to_loc:
        return 0

    key = (from_loc, to_loc)
    if key in TRAVEL_TIMES:
        return TRAVEL_TIMES[key]

    # Reverse lookup
    key = (to_loc, from_loc)
    if key in TRAVEL_TIMES:
        return TRAVEL_TIMES[key]

    return 9999


def get_optimal_step_time(from_boss, to_boss):
    """Get best travel time (direct vs via entrance)."""
    direct = get_direct_travel_time(from_boss, to_boss)
    via_entrance = WIRE_SWITCH_TIME + get_direct_travel_time('ENTRANCE', to_boss)

    if direct <= via_entrance:
        return (direct, 'direct')
    return (via_entrance, 'entrance')


def find_greedy_route(alive_bosses):
    """
    Greedy nearest-neighbor: always go to closest unvisited boss.
    O(n²) complexity - very fast.
    Returns route with 'E' markers when via entrance is faster.
    Example: [1, 7, 'E', 5] means go to 1, then 7, then wire switch to entrance, then 5.
    """
    if not alive_bosses:
        return ([], 0, [])

    if len(alive_bosses) == 1:
        time = get_direct_travel_time('ENTRANCE', alive_bosses[0])
        return ([alive_bosses[0]], time, [{'from': 'ENTRANCE', 'to': alive_bosses[0], 'time': time, 'method': 'direct'}])

    unvisited = set(alive_bosses)
    route = []
    details = []
    total_time = 0
    current = 'ENTRANCE'

    while unvisited:
        # Find nearest unvisited boss
        best_next = None
        best_time = float('inf')
        best_method = 'direct'

        for boss in unvisited:
            if current == 'ENTRANCE':
                time = get_direct_travel_time('ENTRANCE', boss)
                method = 'direct'
            else:
                time, method = get_optimal_step_time(current, boss)

            if time < best_time:
                best_time = time
                best_next = boss
                best_method = method

        # Add 'E' marker if going via entrance
        if best_method == 'entrance':
            route.append('E')

        # Move to best next boss
        route.append(best_next)
        details.append({
            'from': current,
            'to': best_next,
            'time': best_time,
            'method': best_method
        })
        total_time += best_time
        unvisited.remove(best_next)
        current = best_next

    return (route, total_time, details)


def main():
    read_from_stdin = '--stdin' in sys.argv
    verbose = '--verbose' in sys.argv or '-v' in sys.argv

    if read_from_stdin:
        alive_str = sys.stdin.read().strip()
    else:
        args = [a for a in sys.argv[1:] if not a.startswith('-')]
        alive_str = args[0] if args else ""

    alive_bosses = []
    for x in alive_str.split():
        try:
            alive_bosses.append(int(x))
        except ValueError:
            pass

    if not alive_bosses:
        print("")
        return

    route, total_time, details = find_greedy_route(alive_bosses)

    if verbose:
        print(f"Alive bosses: {alive_bosses}", file=sys.stderr)
        print(f"Optimal route: {route}", file=sys.stderr)
        print(f"Total time: {total_time}s", file=sys.stderr)
        print("", file=sys.stderr)
        for step in details:
            method_str = "(via entrance)" if step['method'] == 'entrance' else ""
            print(f"  {step['from']} -> {step['to']}: {step['time']}s {method_str}", file=sys.stderr)

    print(" ".join(str(x) for x in route))


if __name__ == "__main__":
    main()
