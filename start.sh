#################################################
#  start the program by running sh start.sh
#
#  file -> gclinks.txt - holds the urls we have already downloaded
#    this way we don't download something we aready consumed
# 
#  dir -> html_files - hold a copy of the html files downloaded
#    we permanently hold on to these for re-reading
#  
#  dir -> gc_audio - will hold the audio conversions of the texto

#download the main page with all the links
curl ADD_URL_HERE > gchtml.tmp  ##### ADD URL IN PRODUCTION

# get all anchor tags
grep -Eoi '<a[^>]+>' gchtml.tmp |    

# extract the links inside the anchor tags
grep -Eo 'href="[^\"]+"' | 

# get all links that contain the phrase
grep "gc-v" |
 
# remove the begining of the link
sed 's/href=//g' |

# remove quotes
sed 's/\"//g' > gclinks.tmp

#################################
# counter will tell us if there were any urls added
new_url_counter=0

# loop through all links and add them to appropprate files
while read -r link; do
  # if we dont find the URL in the file
  if ! grep -Fxq "$link" gclinks.txt; then

    #add to file
    echo $link >> ./gclinks.txt

    #echo action
    echo "new url found: $link"

    #make a list of links to download
    echo "$link" >> ./links_to_download.tmp

    #increment new url counter
    new_url_counter=$((new_url_counter+1))

  fi	
done < gclinks.tmp

##################################

# error handeling if no new urls found
if [ "$new_url_counter" -eq 0 ]; then
  echo "NO NEW URLS FOUND"
  exit
fi

##################################

#create dir to hold downloaded html if it does not exist
# -p no error reported if dir already exists
mkdir -p html_files
cd ./html_files

#################################

# This block takes the URL and downloads the HTML
while read -r url; do
  
  #set variable to name file
  filename=$(basename $url)
  echo "downloading $filename"
  curl $url >> ./$filename  

  echo $filename >> ../files_to_convert.tmp
done < ../links_to_download.tmp

cd ..

#################################
# this block we will strip the text out of the html 
# then convert it to audio

mkdir -p gc_audio
cd gc_audio

while read -r fname; do
  cat ../html_files/$fname |  
  grep -o '<div class="post-content entry-content">.*</div>' |

  # remove tags from html file # remove tags
  sed -e 's/<[^>]*>//g' | 

  # remove any word that start with & # html leftovers
  sed 's/\&[^ ]*//g' | 
  say -o $fname.aiff
  echo "just output $fname.aiff"
  # if you want mp3s convert the aiff to mp3 here
done < ../files_to_convert.tmp

cd ..

################################
#cleanup 
rm *.tmp
