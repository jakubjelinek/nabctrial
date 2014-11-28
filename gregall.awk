#!/bin/awk -f
{
  while (match ($0, /\(([^)]*)\|([^)]*)\)/, arr) != 0)
    {
      $0 = substr ($0, 1, RSTART) "[alt:\\gregallchar{" arr[2] "}]" arr[1] ")" substr ($0, RSTART + RLENGTH)
    }
  print
}
