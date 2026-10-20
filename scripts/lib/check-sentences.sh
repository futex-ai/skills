#!/usr/bin/env bash
# The sentence scan of scripts/check.sh. check.sh sources this file; do not
# run it.
#
# Simplified Technical English gives an instruction 20 words or fewer. The
# scan lists each longer sentence in the prose of a Markdown file. It skips
# the frontmatter, the fenced code blocks, the headings, and the table rows.
# A blank line, one of those lines, or a list marker ends a paragraph. A
# sentence can continue on the next line of its paragraph. It ends at a
# `.`, `!`, or `?` before a space or the end of the line. Closing quotes,
# brackets, and backticks can stand between the mark and the space. A word
# is a run of characters without white space. The awk program is POSIX, so
# that BSD awk on macOS gives the same result.
# shellcheck shell=bash

long_sentences() {  # long_sentences <file> <max>: the sentences of <file> over <max> words
  # It prints one line per sentence. Tabs separate the fields: the line where
  # the sentence starts, its word count, and its first eight words.
  awk -v max="$2" '
    # The frontmatter runs from a first line of --- to the next ---.
    FNR == 1 && $0 == "---" { front = 1; next }
    front { if ($0 == "---") front = 0; next }

    # A run of three or more backticks or tildes opens a fenced block. A run
    # of the same character that is at least as long closes it, alone on
    # its line.
    match($0, /^[[:space:]]*(```+|~~~+)/) {
      rest = substr($0, RSTART + RLENGTH)
      run = substr($0, RSTART, RLENGTH)
      sub(/^[[:space:]]+/, "", run)
      if (fence == "") { end_sentence(); fence = run; next }
      if (substr(run, 1, 1) == substr(fence, 1, 1) && length(run) >= length(fence) &&
          rest !~ /[^[:space:]]/) { fence = ""; next }
    }
    fence != "" { next }

    # A blank line, a heading, or a table row ends the paragraph.
    /^[[:space:]]*$/ || /^[[:space:]]*[#|]/ { end_sentence(); next }

    {
      line = $0
      # A list marker starts an item. Drop the marker and a task checkbox.
      if (sub(/^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+/, "", line)) {
        end_sentence()
        sub(/^\[[ xX]\][[:space:]]+/, "", line)
      }
      line = line " "
      while (match(line, /[.!?][])"\047`]*[[:space:]]+/)) {
        add(substr(line, 1, RSTART + RLENGTH - 1))
        end_sentence()
        line = substr(line, RSTART + RLENGTH)
      }
      add(line)
    }

    END { end_sentence() }

    function add(text,   n, i, w) {  # add the words of text to the sentence
      n = split(text, w, " ")
      if (n > 0 && words == 0) start = FNR
      for (i = 1; i <= n; i++) {
        words++
        if (words <= 8) lead = lead (words > 1 ? " " : "") w[i]
      }
    }

    function end_sentence() {  # print the sentence when it is too long
      if (words > max) printf "%d\t%d\t%s\n", start, words, lead
      words = 0
      lead = ""
    }
  ' "$1"
}
