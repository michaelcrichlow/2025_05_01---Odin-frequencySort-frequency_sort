package test

import "core:fmt"
import "core:mem"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:math"
import "core:sys/windows"
import "core:time"
import "core:unicode"
import "base:runtime"
import p_str "python_string_functions"
import p_list "python_list_functions"
print :: fmt.println
printf :: fmt.printf
import "core:sort"

DEBUG_MODE :: true

main :: proc() {

	when DEBUG_MODE {
		// tracking allocator
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf(
					"=== %v allocations not freed: context.allocator ===\n",
					len(track.allocation_map),
				)
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf(
					"=== %v incorrect frees: context.allocator ===\n",
					len(track.bad_free_array),
				)
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}

		// tracking temp_allocator
		track_temp: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track_temp, context.temp_allocator)
		context.temp_allocator = mem.tracking_allocator(&track_temp)

		defer {
			if len(track_temp.allocation_map) > 0 {
				fmt.eprintf(
					"=== %v allocations not freed: context.temp_allocator ===\n",
					len(track_temp.allocation_map),
				)
				for _, entry in track_temp.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track_temp.bad_free_array) > 0 {
				fmt.eprintf(
					"=== %v incorrect frees: context.temp_allocator ===\n",
					len(track_temp.bad_free_array),
				)
				for entry in track_temp.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track_temp)
		}
	}

    // main work
    print("Hello from Odin!")
    windows.SetConsoleOutputCP(windows.CODEPAGE.UTF8)
    start: time.Time = time.now()

    // code goes here
    // print(frequency_sort("cabcbc", context.temp_allocator))
    print(frequencySort("tree", context.temp_allocator))
    print(Counter([]int{1, 1, 2, 3}))

    // iterations := 1_000
    // total_time := time.Duration(0)
    
    // for _ in 0 ..< iterations {
    //     start := time.now()
    //     // code to test goes here
    //     frequency_sort("cabcbc", context.temp_allocator)
    //     total_time += time.since(start)
    // }
    // print("Average time:", int(total_time) / iterations, "ns")

    // // iterations := 1_000
    // total_time1 := time.Duration(0)
    
    // for _ in 0 ..< iterations {
    //     start1 := time.now()
    //     // code to test goes here
    //     frequencySort("cabcbc", context.temp_allocator)
    //     total_time1 += time.since(start1)
    // }
    // print("Average time:", int(total_time1) / iterations, "ns")

    elapsed: time.Duration = time.since(start)
    print("Odin took:", elapsed)

    free_all(context.temp_allocator)


}

frequencySort :: proc(s: string, allocator := context.allocator) -> string {
    freq := Counter(s)
    print(freq) // map[a=1, c=3, b=2]
    
    RuneCount :: struct {
        _rune : rune,
        count: int
    }

    rune_counts := make([dynamic]RuneCount, len(freq), allocator = allocator)
	i := 0
	for key, val in freq {
		rune_counts[i] = RuneCount{key, val}
		i += 1
	}
    // print(rune_counts) // [RuneCount{_rune = a, count = 1}, RuneCount{_rune = c, count = 3}, RuneCount{_rune = b, count = 2}]

    slice.sort_by(rune_counts[:], proc(i, j: RuneCount) -> bool {return i.count > j.count})
    //                                                                          ^
    //                                                                          |
    //                                                                       important!
    // The < puts it in increasing order. The > puts it in decreaing order.
    // print(rune_counts)

    b: strings.Builder
    strings.builder_init(&b, 0, len(s), allocator)
    // code goes here
    for val in rune_counts {
        for _ in 0 ..< val.count {
            strings.write_rune(&b, val._rune)
        }
    }

    final_string := strings.to_string(b)
    
    return final_string

    // do to:
    // 1.) sort rune_counts by count
    // 2.) Make a string builder (b)
    // 3.) iterate through rune_counts and `strings.write_rune(&b, val)` to the string builder `count` times.
    // 4.) make a final_string --> `final_string = strings.to_string(b)`
    // 5.) return it --> return final_string
    
    // return ""
}

// code by karl_zylinski (thank you!)
frequency_sort :: proc(s: string, allocator := context.allocator) -> string {
    occurances := make(map[rune]int, context.temp_allocator)

    for c in s {
        occurances[c] += 1
    }

    Occurance :: struct {
        r: rune,
        n: int,
    }

    sorted_occurances := make([dynamic]Occurance, 0, len(occurances), context.temp_allocator)

    for k, v in occurances {
        append(&sorted_occurances, Occurance { r = k, n = v })
    }

    slice.sort_by(sorted_occurances[:], proc(i, j: Occurance) -> bool { return j.n < i.n })
    b := strings.builder_make_len_cap(0, len(s), allocator)

    for o in sorted_occurances {
        for _ in 0..<o.n {
            strings.write_rune(&b, o.r)
        }
    }
    
    return strings.to_string(b)
}

/*
from collections import Counter

def frequencySort(s: str) -> str:
    freq = Counter(s)  # Count occurrences of each character
    sorted_chars = sorted(s, key=lambda x: freq[x], reverse=True)  # Sort by frequency
    return "".join(sorted_chars)

def main() -> None:
    print(frequencySort("tree"))

if __name__ == '__main__':
    main()
*/
