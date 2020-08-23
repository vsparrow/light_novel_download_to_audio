##### ADD URL IN PRODUCTION IF YOU REMOVE IT
url="https://*****/jack-of-all-trades-*/"
# This is needed to overcome content obfuscation see line 87
baseurl="https://*****/"

#download the main page with all the links
curl $url > list_of_links_from_web.tmp

# get all anchor tags
grep -Eoi '<a[^>]+>' list_of_links_from_web.tmp |

# extract the links inside the anchor tags
grep -Eo 'href="[^\"]+"' |

# get all links that contain the phrase
grep "20" | #all the links we want have this term in common

# remove the begining of the link
sed 's/href=//g' |

#remove quotes
sed 's/\"//g' >  jack_links.tmp


####################################################
# Add newly found links to our database aka file
####################################################

# counter will tell us if there were any urls added
new_url_counter=0

# make database file if it does not exist
if [ ! ./database ]; then
  touch database
fi

# loop through all links and add them to appropprate files
while read -r link; do

  #if we dont find the URL in our database
  if ! grep -xq "$link" database; then

    # add to file
    echo $link >> database

    # echo action to inform
    echo "new url found: $link"

    # add new links to temp file to be read so they are downloaded
    echo "$link" >> links_to_download.tmp

    # increment counter
    new_url_counter=$((new_url_counter+1))

  fi

done < jack_links.tmp

# echo message if no new urls found
if [ "$new_url_counter" -eq 0 ]; then

  echo "NO NEW URLS FOUND"
  echo $new_url_counter
  # if no new urls, no need to continue 
  exit

fi

####################################################
# download the new urls that are found
####################################################
# create dir to hold doownload files if it does not exist
mkdir -p html_files
cd ./html_files

# loop through temp file of new links
while read -r url; do

  # filename is set here
  filename=$(basename $url)
  echo "downloading $filename"
  curl $url > ./$filename

  #this will be used to help convert text to audio
  echo $filename >> ../files_to_convert.tmp

  # *** The website obfuscates 1/2 the chapter in a different url **
  url2="${baseurl}${filename}/"
  filename2="${filename}a"
  curl $url2 > ./$filename2
  echo $filename2 >> ../files_to_convert.tmp

done < ../links_to_download.tmp

#return to main dir
cd ..

####################################################
# extract text
####################################################

mkdir -p audio
cd audio

while read -r filename; do
  cat ../html_files/$filename |

  # this is where we can find the desired content
  sed -n  '/<div class="the-content">/,/<div class="sharedaddy sd-sharing-enabled">/p' | 

  # get p tags
  grep -o '<p>.*</p>' |

  # remove html tags. ex, <p>
  sed -e 's/<[^>]*>//g' |

  # remove any word that start with & # html leftovers
  sed 's/\&[^ ]*//g' | # re-enable when using on mac
  #sed 's/\&[^ ]*//g' > $filename.txt # uncomment when using on linux

  # export to audio
  say  -o $filename.aiff #only works on Mac not linux # use festival for linux
  echo "Just output $filename.aiff"

done < ../files_to_convert.tmp

####################################################
# cleanup
####################################################

rm *.tmp
