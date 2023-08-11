#!/bin/bash
# Define hour range and it should not exceed 0~23 hours (default is 0~23)
hour_start=${hour_start:-0}
hour_end=${hour_end:-23}

if ((hour_start < 0 || hour_start > 23 || hour_end < 0 || hour_end > 23)); then
  echo "Hour range should be 0~23"
  exit 1
fi

# Get interval count (default is 2)
interval_count=${interval_count:-2}

# Correct the time zone to UTC+0
time_zone=${time_zone:-'UTC+0'}
time_diff=$(echo $time_zone | sed 's/^[^+-]*//') && time_num=${time_diff:1} && time_sign=${time_diff:0:1}
[ ${time_num%.*} -lt 0 -o ${time_num%.*} -gt 12 ] && echo "Current $time_zone not supported!!" && exit 1
[ ${time_sign} == "+" ] && operator="-"
[ ${time_sign} == "-" ] && operator="+"
hour_start_utc=$(($hour_start ${operator} ${time_num%.*}))
[ $hour_start_utc -lt 0 ] && hour_start_utc=$(($hour_start_utc + 24))
hour_end_utc=$(($hour_end ${operator} ${time_num%.*}))
[ $hour_end_utc -lt 0 ] || [ $hour_start_utc -gt $hour_end_utc ] && hour_end_utc=$(($hour_end_utc + 24))

# Divide into n intervals of equal length
interval_length=$(( ($hour_end_utc - $hour_start_utc + 1) / $interval_count ))
remainder=$(( ($hour_end_utc - $hour_start_utc + 1) % $interval_count ))

# If the length of each interval is less than 1 hour, output an error message and exit
[ $interval_length -lt 1 ] && echo "Interval length is less than 1 hour. Please reduce the number of intervals or modify the hour range." && exit 1

# Construct a list of intervals
for ((i = 1; i <= interval_count; i++)); do
    (( i <= remainder )) && array[i-1]=$(( interval_length + 1 )) || array[i-1]=$interval_length
done
sorted=( $(shuf -e "${array[@]}") )
echo "Length of each interval: ( ${sorted[@]} )"
interval_start=$hour_start_utc
intervals=()
for ((i = 1; i <= interval_count; i++)); do
    interval_end=$((interval_start + ${sorted[i-1]} - 1))
    intervals+=("$interval_start-$interval_end")
    echo "Interval $i: $interval_start-$interval_end"
    interval_start=$((interval_end + 1))
done

# Get the interval that the current time falls into
current_hour=$(date +%-H)
[[ $current_hour -lt $hour_start_utc ]] && current_hour=$(( $current_hour + 24))
for ((i = 0; i < interval_count; i++)); do
    interval=${intervals[i]}
    interval_start=${interval%-*}
    interval_end=${interval#*-}
    if [ "$current_hour" -ge "$interval_start" ] && [ "$current_hour" -le "$interval_end" ]; then
        current_interval=$i
        break
    fi
done

# If the current time is not within any interval or is in the last interval, do not remove any intervals; otherwise, remove the current interval and all intervals before it
if [ -z $current_interval ] || [ $current_interval -eq $((interval_count - 1)) ]; then
    intervals=("${intervals[@]}")
else
    intervals=("${intervals[@]:$((current_interval + 1))}")
fi

# Generate a random hour within each remaining interval
cron_hours=""
for interval in "${intervals[@]}"; do
    interval_start=${interval%-*}
    interval_end=${interval#*-}
    if [ $current_hour -ge $interval_start -a $current_hour -le $interval_end ]; then
        random_hour=$((RANDOM % (current_hour - interval_start + 1) + interval_start))
        [ $interval_count -eq 1 ] && [ $random_hour -eq $hour_start ] && [ $random_hour -eq $current_hour ] && random_hour=$hour_end
    else
        random_hour=$((RANDOM % (interval_end - interval_start + 1) + interval_start))
    fi
    [ $random_hour -ge 24 ] && random_hour=$((random_hour - 24))
    cron_hours="$cron_hours$random_hour,"
done
# Remove trailing comma
cron_hours=${cron_hours%?}

# Generate a random minute (0~59). If the current hour is in the last interval, the minute should be less than or equal to the current minute.
if [ $current_interval ] && [ $current_interval -eq $((interval_count - 1)) ] && [ $current_hour -eq $random_hour ]; then
    current_minute=$(date +%-M)
    cron_minute=$((RANDOM % (current_minute + 1)))
else
    cron_minute=$((RANDOM % 60))
fi

# Custom cron DayofMonth Month DayofWeek (default is "* * *")
cron_dmw=${cron_dmw:-"* * *"}

# Generate the cron expression
cron_expression="$cron_minute $cron_hours ${cron_dmw}"
echo "Generated cron expression: $cron_expression"

# Replace the cron expression in the YAML file
workflow_name=${workflow_name}
workflow_path=$(echo "${workflow_name}" | sed 's/^[^.]*\///;s/@.*$//')
sed -i "/^[^#]*schedule:/,+5{ /#/! s@cron: .*['\"]\?@cron: \"$cron_expression\"@; }" ${workflow_path}

# Commit the modified YAML file to the repository
push_switch=${push_switch}
if [[ $push_switch == true ]]; then
    author=${author}
    keep_history=${keep_history}
    ref_branch=${ref_branch}
    token=${github_token}
    repository=${repository}
    [[ ${author} =~ ^([^\ ]+)[[:space:]]*\<*([^\>]+)\>*$ ]] && username=${BASH_REMATCH[1]} && email=${BASH_REMATCH[2]}

    git config user.name "$username"
    git config user.email "$email"
    git remote set-url origin https://${token}@github.com/${repository}.git

    if [[ $keep_history == true ]]; then
        message=$(git log --pretty=format:"%s" $h -1)
        if [[ $message == "Update Random Cron" ]]; then
            git add $workflow_path
            git stash -u -k
            git commit --amend --reset-author -m "Update Random Cron"
            git stash pop
            git reflog expire --expire=now --expire-unreachable=now --all
            git gc --aggressive --prune=now
            git push -f origin ${ref_branch}
        else
            git add $workflow_path
            git stash -u -k
            git commit -m "Update Random Cron"
            git stash pop
            git push origin ${ref_branch}
        fi
    else
        git checkout --orphan tmp_branch
        git rm -rf --cached .
        git add -A
        git commit -m "Update Random Cron"
        git show-ref -q --heads ${ref_branch} && git branch -D ${ref_branch}
        git branch -m ${ref_branch}
        git push -f origin ${ref_branch}
    fi
fi

