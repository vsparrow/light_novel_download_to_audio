# This is to recover links that could not download 
# some sites limit the pages you can download at one time

# **** when running the script use bash recover_0kb_files.sh
# using sh instead of bash will casue ubuntu to use dash.
# which makes for some unexpected results in redirection

# place this in the main directory where database is located

cd html_files

while read -r link; do

  # The filenames are the same as the basename of the link
  filename=$(basename $link)
  # -s means fileexists and is not empty
  if [ -s $filename ] 
  then
    echo  "$filename already exists"
  else
    echo "updating $filename"

    # some of the urls have 3 slashes after .com
    updated_link1=$(sed "s/com\/\/\//com\//g" <<< $link)

    # some of the urls have 2 slashes after .com
    updated_link=$(sed "s/com\/\//com\//g" <<< $updated_link1)
    # -L to follow redirection of URLs
    curl -L $updated_link > ./$filename

    # Check to see if the file is of expected size
    # check filesize  c%s = output in bytes
    filesize=$(stat -c%s "$filename")
    if(($filesize < 10485)); then
      echo $filename >> download_error.tmp
      echo $updated_link >> download_error.tmp
      echo "" #for spacing
    fi

    # to combat rate limiting, pre-limit the downloads yourself
    #echo "sleeping for 120s for rate limiting"
    #sleep 120s

  fi


done <  ../database

# This is to alert the user that some files that still need attention
# find files that are 10Kb or less
echo "**********************************"
echo "**********************************"
echo "**********************************"
echo "files below are 10kb or less"
echo "**********************************"
echo "**********************************"
echo "**********************************"

cat download_error.tmp
echo ""
find . -type f -size -10485c # alert for files not caught in error file
rm download_error.tmp

cd ..
