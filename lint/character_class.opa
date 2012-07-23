/**
 * Lint rules for character classes.
 *
 * These rules can detect things like:
 *  [a-cd] => [a-d]
 *  [x\-a-c] => [a-cx-]
 *  etc.
 *
 *
 *
 *   This file is part of RiskyBird
 *
 *   RiskyBird is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   RiskyBird is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with RiskyBird.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Julien Verlaguet
 * @author Alok Menghrajani
 */

module LintCharacterClass {
  function lint_result character_class(regexp re, int id, character_class char_class, lint_result res) {
    res = List.fold(do_item, char_class.class_ranges, res)
    res = check_set(re, id, char_class, res)

    // Check if the character class is empty.
    if (List.is_empty(char_class.class_ranges)) {
      err = if (char_class.neg) {
        {
          lint_rule: {empty_character_class},
          title: "empty negative character class",
          body: "[^] is equivalent to . and will match any character.",
          class: "",
          patch: {none}
        }
      } else {
        {
          lint_rule: {empty_character_class},
          title: "empty character class",
          body: "[] is an empty character class and will never match.",
          class: "",
          patch: {none}
        }
      }
      RegexpLinter.add(res, err)
    } else {
      res;
    }
  }

  function lint_result do_item(class_range i, lint_result res) {
    match (i) {
      case {~start_char, ~end_char}:
        start = class_atom_to_int(start_char)
        end = class_atom_to_int(end_char)

        start2 = RegexpStringPrinter.print_class_atom(start_char)
        end2 = RegexpStringPrinter.print_class_atom(end_char)

        if (start > end) {
          err = {
            lint_rule: {invalid_range_in_character_class},
            title: "invalid range in character class",
            body: "[{start2}-{end2}] is invalid.",
            class: "alert-error",
            patch: {none}
          }
          RegexpLinter.add(res, err)
        } else if (start == end) {
          err = {
            lint_rule: {non_optimal_class_range},
            title: "useless range in character class",
            body: "[{start2}-{end2}] is useless.",
            class: "",
            patch: {none}
          }
          RegexpLinter.add(res, err)
        } else if (start_char == {char: "A"} && end_char == {char: "z"}) {
          err = {
            lint_rule: {lazy_character_class},
            title: "programmer laziness",
            body: "When you write A-z instead of A-Za-z, you are matching on 6 extra characters!",
            class: "",
            patch: {none}
          }
          RegexpLinter.add(res, err)
        } else {
          res;
        }
      case _:
        res
    }
  }

  function class_atom int_to_class_atom(int i) {
    if (i<33) {
      {escaped_char: {hex_escape_sequence: RegexpLinterHelper.int_to_hex(i)}}
    } else if (i < 127) {
      {char: textToString(Text.from_character(i))}
    } else if (i < 256) {
      {escaped_char: {hex_escape_sequence: RegexpLinterHelper.int_to_hex(i)}}
    } else {
      {escaped_char: {unicode_escape_sequence: RegexpLinterHelper.int_to_unicode_hex(i)}}
    }
  }

  function int class_atom_to_int(class_atom class_atom) {
    match (class_atom) {
      case {~char}:
        int_of_first_char(char)
      case {~escaped_char}:
        RegexpLinterHelper.escaped_char_to_int(escaped_char)
    }
  }

  /**
   * The easiest way to lint a character set is to rewrite
   * the set and then compare the results. If the length
   * of the resulting set is shorter than the length
   * of the initial set, we will suggest a fix.
   */
  function lint_result check_set(regexp re, int character_class_id, character_class set, lint_result res) {
    recursive function intset range_to_charmap(int start, int end, intset map) {
      map = IntSet.add(start, map)
      if (start == end) {
        map;
      } else {
        range_to_charmap(start+1, end, map)
      }
    }

    function intset set_to_charmap(class_range i, intset map) {
      match (i) {
        case {~class_atom}:
          IntSet.add(class_atom_to_int(class_atom), map)
        case {~start_char, ~end_char}:
          range_to_charmap(class_atom_to_int(start_char), class_atom_to_int(end_char), map)
      }
    }

    if (Set.mem({invalid_range_in_character_class}, res.matched_rules) ||
        Set.mem({non_optimal_class_range}, res.matched_rules) ||
        Set.mem({lazy_character_class}, res.matched_rules)) {
      // if rules 5, 6 or 7 matched, we'll skip this one.
      res;
    } else {
      // normalize the character_class
      map = List.fold(set_to_charmap, set.class_ranges, IntMap.empty)
      new_set = {set with class_ranges: LintCharacterClass.denormalize_charmap(map)}

      s1 = RegexpStringPrinter.print_character_class(new_set)
      s2 = RegexpStringPrinter.print_character_class(set)
      if (s1 != s2) {
        regexp new_regexp = RegexpFixNonOptimalCharacterRange.regexp(re, character_class_id, new_set)
        err = {
          lint_rule: {non_optimal_class_range},
          title: "non optimal character range",
          body: "A shorter/cleaner way to write {s2} is {s1}",
          class: "",
          patch: {some: RegexpStringPrinter.print_regexp(new_regexp)}
        }
        RegexpLinter.add(res, err)
      } else {
        res;
      }
    }
  }

  /**
   * Takes a "charmap" (set of ints) and converts it back to a list of
   * class_range.
   *
   * The process is pretty simple, but we need to handle - in a special way:
   * - if - is the start or end of a range, we keep it
   * - if - appears by itself, we push it to the end
   *
   * TODO: A good test: [(\-x] should convert to [(x-]
   * And [\]] should remain [\]]
   */
  function list(class_range) denormalize_charmap(intset map) {
    recursive function (list(class_range), map) charmap_to_range(
        int min,
        int max,
        intset map,
        list(class_range) class_ranges) {
      map = IntSet.remove(max, map)
      if (IntSet.mem(max+1, map)) {
        charmap_to_range(min, max+1, map, class_ranges)
      } else if (min == max) {
        class_range = {class_atom: int_to_class_atom(min)}
        class_ranges = List.cons(class_range, class_ranges)
        (class_ranges, map)
      } else if (min+1 == max) {
        class_range = {class_atom: int_to_class_atom(min)}
        class_ranges = List.cons(class_range, class_ranges)
        class_range = {class_atom: int_to_class_atom(max)}
        class_ranges = List.cons(class_range, class_ranges)
        (class_ranges, map)
      } else {
        class_range = {start_char: int_to_class_atom(min), end_char: int_to_class_atom(max)}
        class_ranges = List.cons(class_range, class_ranges)
        (class_ranges, map)
      }
    }

    recursive function charmap_to_set(intset map, list(class_range) class_ranges) {
      if (IntSet.is_empty(map)) {
        // we are done
        class_ranges;
      } else {
        (int min, _) = IntMap.min_binding(map)
        (class_ranges, map) = charmap_to_range(min, min, map, class_ranges)
        charmap_to_set(map, class_ranges)
      }
    }

    list(class_range) r = charmap_to_set(map, [])

    // Filter out "-" if its in r
    // If we see "[", we keep it but escape it
    t = List.fold_right(
      function (r, class_range e) {
        match (e) {
          case {class_atom: {char: "-"}}:
            {ll: r.ll, dash: true}
          case {class_atom: {char: "["}}:
            {
              ll: List.cons(
                {class_atom: {escaped_char: {identity_escape: "["}}},
                r.ll),
              dash: r.dash
            }
          case {class_atom: {char: "]"}}:
            {
              ll: List.cons(
                {class_atom: {escaped_char: {identity_escape: "]"}}},
                r.ll),
              dash: r.dash
            }
          case {class_atom: {char: "\\"}}:
            {
              ll: List.cons(
                {class_atom: {escaped_char: {identity_escape: "\\"}}},
                r.ll),
              dash: r.dash
            }
          case _:
            {ll: List.cons(e, r.ll), dash: r.dash}
        }
      },
      r,
      {
        ll: [],
        dash: false,
      }
    )
    // Add back "-" if we filtered it out
    r = if (t.dash) {
      List.cons({class_atom: {char: "-"}}, t.ll)
    } else {
      t.ll;
    }
    // Ugly, but works
    List.rev(r)
  }
}
