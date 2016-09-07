#! /bin/bash

### This script queries the Daily Info site, pulls their listing and compares to the last listing it saw. If there is a difference, it is formated (a bit :)) and sent to me via email.

### I am using mailutils to send emails, and had to set up ssmtp.
### In setting it, I followed online instructions (along the lines of: http://rianjs.net/2013/08/send-email-from-linux-server-using-gmail-and-ubuntu-two-factor-authentication), with the caveat of setting hostname=localhost to make it work with gmail.


## TODO: This should be done smarter, to work for other people
cd ~/work/dailyinfocrawler/homes

# So that I know when was the script run last time
touch last_cron_job.txt


# Download current state
curl http://www.dailyinfo.co.uk/homes-to-let > current_state_raw.txt

# Make file pretty and indented
tidy -config ../tidy.conf current_state_raw.txt  > current_state_clean.txt

# Remove unnecessary data before the first listing
PATTERN='ul id="pl" '
sed "0,/$PATTERN/d" < current_state_clean.txt > current_state_shorter.txt

# Remove two lines that do change every time
cp current_state_shorter.txt current_state.txt
sed '/www.facebook.com/d' current_state.txt > tmp.txt; cp tmp.txt current_state.txt
sed '/NREUM/d' current_state.txt > tmp.txt; cp tmp.txt current_state.txt
sed '/queue.script(/d' current_state.txt > tmp.txt; cp tmp.txt current_state.txt
sed '/<b>Enter the text of your add here:/d' current_state.txt > tmp.txt; cp tmp.txt current_state.txt


# In case previous state is empty, just make it the same to current state to silenlty swallow starting conditions when nothing has yet been pulled.
if ! [ -f previous_state.txt ]
then
    cp current_state.txt previous_state.txt
fi



# Compare the previous and current version
diff -w current_state.txt previous_state.txt > diff_state.txt

# Only show lines ADDED in current state, not those that are missing
cat diff_state.txt | grep -E "^<" > tmp.txt; cp tmp.txt diff_state.txt

# Make links open the base property site, not send page
sed -i 's/mask_email_send.php?ad_id/property.php?id/g' diff_state.txt

# Add space before main text
sed -i 's/<span class="a_text">/<span class="a_text">\n----------------\n/g' diff_state.txt

# Emphasize GBP signs
sed -i 's/&#163/\n _____GBP: /g' diff_state.txt


# Print out for debugging
cat diff_state.txt


# If there is a diff, send email
if [ -s diff_state.txt ]
then
    cat diff_state.txt | mail -s "[DI] New Homes" ivo.sluganovic@gmail.com
    echo "Email notification sent!"
fi

# Make the previous_state become what is now curent_state
cp current_state.txt previous_state.txt
