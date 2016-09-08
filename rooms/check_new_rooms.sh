#! /bin/bash

### This script queries the Daily Info site, pulls their listing and compares to the last listing it saw. If there is a difference, it is formated (a bit :)) and sent to me via email.

### I am using mailutils to send emails, and had to set up ssmtp.
### In setting it, I followed online instructions (along the lines of: http://rianjs.net/2013/08/send-email-from-linux-server-using-gmail-and-ubuntu-two-factor-authentication), with the caveat of setting hostname=localhost to make it work with gmail.


## TODO: This should be done smarter, to work for other people
cd ~/work/dailyinfocrawler/rooms

# So that I know when was the script run last time
touch last_cron_job.txt

# Download current state
curl http://www.dailyinfo.co.uk/rooms-to-let > current_state_raw.txt

# Extract only room links
egrep -o 'to\-let/[0-9]{7}' current_state_raw.txt > current_state.txt

# Make them proper, links
sed -i -e 's|^|http://www.dailyinfo.co.uk/rooms-|' current_state.txt

# Make them sorted and unique
sort -u current_state.txt > tmp.txt; cp tmp.txt current_state.txt


# In case previous state is empty, just make it the same to current state to silenlty swallow starting conditions when nothing has yet been pulled.
if ! [ -f previous_state.txt ]
then
    cp current_state.txt previous_state.txt
fi

# Compare the previous and current version
diff -w current_state.txt previous_state.txt > diff_state.txt

# Only show lines ADDED in current state, not those that are missing
cat diff_state.txt | grep -E "^<" > tmp.txt; cp tmp.txt diff_state.txt

# Print out for debugging
cat diff_state.txt


# If there is a diff, send email
if [ -s diff_state.txt ]
then
    cat diff_state.txt | mail -s "[DI] New Rooms" ivo.sluganovic@gmail.com
    echo "Email notification sent!"
fi

# Make the previous_state become what is now curent_state
cp current_state.txt previous_state.txt
