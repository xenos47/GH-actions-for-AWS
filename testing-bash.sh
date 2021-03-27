#! /bin/bash

var=11
slots=3
result=$((var / slots))
k=$((var % slots ))
for ((i=0; i<k; i++)); do
  variableLengthArray[i]=$(( result + 1 ))
done
for ((i=k; i < slots; i++)); do
 variableLengthArray[i]=$result
done
echo "$result"
