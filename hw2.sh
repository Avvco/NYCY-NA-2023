#!/bin/sh

# ./hw2.sh -i hw2-sample/generated-1.hw2 -o test -c csv

# Function to display help message
show_help() {
  echo "hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]" >&2
  echo "Available Options:" >&2
  echo "-i: Input file to be decoded" >&2
  echo "-o: Output directory" >&2
  echo "-c csv|tsv: Output files.[ct]sv" >&2
  echo "-j: Output info.json" >&2
}

# Initialize variables
output_format=""
output_json=1

# Parse command-line arguments
while getopts ":i:o:c:j" opt; do
  case $opt in
    i) input_file="$OPTARG" ;;
    o) output_dir="$OPTARG" ;;
    c) output_format="$OPTARG" ;;
    j) output_json=0 ;;
    \?)
      # echo "Invalid option: -$OPTARG" >&2
      show_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      show_help
      exit 1
      ;;
  esac
done

# Check if required arguments are provided
if [ -z "$input_file" ] || [ -z "$output_dir" ]; then
  echo "Input file, output directory, and output format (-c) are required." >&2
  show_help
  exit 1
fi

# Check if output format is valid
# if output_format exist then check if is csv or tsv
if [ -n "$output_format" ]; then
  if [ "$output_format" != "csv" ] && [ "$output_format" != "tsv" ]; then
    echo "Invalid output format: $output_format" >&2
    show_help
    exit 1
  fi  
fi

# Create output directory if it doesn't exist
rm -rf "$output_dir"
mkdir -p "$output_dir"
echo "0" > "$output_dir"/invalid_file

# Create CSV/TSV file with headers, if -c
if [ "$output_format" = "csv" ]; then
  # echo "filename,size,md5,sha1" > "$output_dir/files.csv"
  printf "%s,%s,%s,%s\n" "filename" "size" "md5" "sha1" > "$output_dir/files.csv"
elif [ "$output_format" = "tsv" ]; then
  # echo "filename\tsize\tmd5\tsha1" > "$output_dir/files.tsv"
  printf "%s\t%s\t%s\t%s\n" "filename" "size" "md5" "sha1" > "$output_dir/files.tsv"
fi

# Function to decode and extract files recursively
decode_and_extract() {
  hw2_file="$1"
  output_dir="$2"

  # Extract data from YAML file to json
  # jsonFiles=$(cat "$hw2_file" | yq -o=json . | tr -d '[:space:]')
  jsonFiles=$(yq -o=json . < "$hw2_file" | tr -d '[:space:]')
  # echo $jsonFiles

  name_out=$(echo "$jsonFiles" | jq -r '.name')
  author=$(echo "$jsonFiles" | jq -r '.author')
  date=$(echo "$jsonFiles" | jq -r '.date')
  # date=date+28800
  date=$((date + 28800))
  formatted_date=$(date -d @"$date" -u +'%Y-%m-%dT%H:%M:%S+08:00')

  echo "$jsonFiles" | jq -c '.files[]' | while read -r file; do
    # Extract fields from each file
    name=$(echo "$file" | jq -r '.name')
    type=$(echo "$file" | jq -r '.type')
    data=$(echo "$file" | jq -r '.data')
    md5=$(echo "$file" | jq -r '.hash.md5')
    sha1=$(echo "$file" | jq -r '.hash."sha-1"')

    dirName=$(dirname "$output_dir"/"$name")
    # echo $output_dir/$name
    # echo $dirName
    mkdir -p "$dirName"

    # echo -e "$(echo $data | base64 -d)" >> $output_dir/$name
    printf '%s\n' "$(echo "$data" | base64 -d)" >> "$output_dir"/"$name"

    size=$(wc -c "$output_dir"/"$name" | awk '{print $1}')

    # echo "Name: $name"
    # echo "Type: $type"
    # echo "Data: $data"
    # echo "MD5: $md5"
    # echo "SHA-1: $sha1"
    # echo "---"  # Separator between files

    if [ "$output_format" = "csv" ]; then
      # echo "$name,$size,$md5,$sha1" >> "$output_dir/files.csv"
      printf "%s,%s,%s,%s\n" "$name" "$size" "$md5" "$sha1" >> "$output_dir/files.csv"
    elif [ "$output_format" = "tsv" ]; then
      # echo "$name\t$size\t$md5\t$sha1" >> "$output_dir/files.tsv"
      printf "%s\t%s\t%s\t%s\n" "$name" "$size" "$md5" "$sha1" >> "$output_dir/files.tsv"
    fi

    true_md5=$(echo "$data" | base64 -d | md5sum | cut -d ' ' -f 1)
    true_sha1=$(echo "$data" | base64 -d | sha1sum | cut -d ' ' -f 1)
    # true_md5=$(md5sum $output_dir/$name | cut -d ' ' -f 1)
    # true_sha1=$(sha1sum $output_dir/$name | cut -d ' ' -f 1)

    if [ "$type" = "hw2" ] && [ "$output_json" -eq 1 ] && [ -z "$output_format" ]; then
      # Recursively decode nested .hw2 files
      echo "$data" | base64 -d > "$output_dir"/tmpp_"$name"
      decode_and_extract "$output_dir"/tmpp_"$name" "$output_dir"
      # rm -f "$output_dir"/"$name"
      rm -f "$output_dir"/tmpp_"$name"
    elif [ "$md5" != "$true_md5" ] || [ "$sha1" != "$true_sha1" ]; then
      number=$(cat "$output_dir"/invalid_file)
      incremented_number=$((number + 1))
      echo $incremented_number > "$output_dir"/invalid_file
    fi
  done

  # generate info.json
  # echo $output_json
  if [ "$output_json" -eq 0 ] ; then
    echo "{\"name\": \"$name_out\", \"author\": \"$author\", \"date\": \"$formatted_date\"}" | jq . > "$output_dir"/info.json
  fi
}

# Start decoding and extraction
decode_and_extract "$input_file" "$output_dir"

# Output the count of invalid files

invalid_file_counts=$(cat "$output_dir"/invalid_file)
# echo $invalid_file_counts
rm -f "$output_dir"/invalid_file
return "$invalid_file_counts"
