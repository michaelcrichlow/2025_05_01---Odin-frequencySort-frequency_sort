package test

import "core:fmt"
import "core:slice"
import "core:strings"
print :: fmt.println

main :: proc() {
    print(frequencySort("tree", context.temp_allocator))
    print(frequencySort("cabcbc", context.temp_allocator))

    free_all(context.temp_allocator)
    // OUTPUT:
    // eert
    // cccbba
}

frequencySort :: proc(s: string, allocator := context.allocator) -> string {
    freq := Counter(s)
    
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

    slice.sort_by(rune_counts[:], proc(i, j: RuneCount) -> bool {return i.count > j.count})

    b: strings.Builder
    strings.builder_init(&b, 0, len(s), allocator)
    // code goes here -------------------------------------
    for val in rune_counts {
        for _ in 0 ..< val.count {
            strings.write_rune(&b, val._rune)
        }
    }
    // ----------------------------------------------------
    final_string := strings.to_string(b)
    
    return final_string
}

