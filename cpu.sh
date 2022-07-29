#!/bin/bash  


if which neofetch >/dev/null; then
  neofetch
fi

show_banner() {
gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        "$1"
}

if [[ "$type" == "GenuineIntel" ]]; then
  current_type="intel"
  current_boost_path="/sys/devices/system/cpu/intel_pstate/no_turbo"
  intel_perf_path="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
  current_perf=$(cat $intel_perf_path)
else 
  current_type="amd"
  current_boost_path="/sys/devices/system/cpu/cpufreq/boost"
  amd_perf_path="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
  amd_perf_paths="/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
  current_perf=$(cat $amd_perf_path)
fi



clear_s() {
  clear && echo -en "\e[3J"
}

is_boost_active=$(cat $current_boost_path)

enable_boost() {
  echo 1 | pkexec tee $current_boost_path
}

disable_boost() {
  echo 0 | pkexec tee $current_boost_path
}


handle_sys_perf() {
  if [[ "$current_type" == "intel" ]]; then
    intel_perf_handler $1
  else
    amd_perf_handler $1
  fi
}

change_intel_cpus () {
  echo $1 > $intel_perf_path
}

intel_perf_handler() {
 option=$1
 if [[ "$option" == "Ultra" ]]; then
  change_intel_cpus "100"
 elif [[ "$option" == "Performance" ]]; then
  change_intel_cpus "70"
 elif [[ "$option" == "Balance" ]]; then
  change_intel_cpus "50"
 elif [[ "$option" == "Powersave" ]]; then
  change_intel_cpus "30"
 fi
}

change_amd_cpus() {
  for cpu in $(ls $amd_perf_paths)
  do
    echo $1 > $cpu
  done
}

amd_perf_handler() {
 option=$1
 if [[ "$option" == "Ultra" ]]; then
  change_amd_cpus "schedutil"
 elif [[ "$option" == "Performance" ]]; then
  change_amd_cpus "performance"
 elif [[ "$option" == "Balance" ]]; then
  change_amd_cpus "powersave"
 elif [[ "$option" == "Powersave" ]]; then
  change_amd_cpus "conservative"
 fi
}

perf_type_handler() {
  if [[ "$1" == "schedutil" ]]; then
    echo "Ultra"
  elif [[ "$1" == "performance" ]]; then
    echo "Performance"
  elif [[ "$1" == "powersave" ]]; then
    echo "Balance"
  elif [[ "$1" == "conservative" ]]; then
    echo "Power Save"
  elif [[ "$1" == "30" ]]; then
    echo "Power Save"
  elif [[ "$1" == "50" ]]; then
    echo "Balance"
  elif [[ "$1" == "70" ]]; then
    echo "Performance"
  elif [[ "$1" == "100" ]]; then
    echo "Ultra"
  fi
}


type=$(cat /proc/cpuinfo | grep -m1 'vendor_id' | awk '{print $3}')
is_active=$( [[ $is_boost_active == 1 ]] &&  echo 'active' ||echo 'not active' )

show_banner "Type: $type your current cpu boost is $is_active"

handle_boost=$( [[ $is_boost_active == 1 ]] && echo 'Disable CPU Boost' || echo 'Enable CPU Boost')
option=$(gum choose --limit 1 "$handle_boost"  "System Performance Settings")

if [[ "$option" == "Disable CPU Boost" ]];then
  gum confirm && disable_boost  || echo "bye"

elif [[ "$option" == "Enable CPU Boost"  ]]; then
  gum confirm && enable_boost || echo "bye"

elif [[  "$option" == "System Performance Settings"  ]]; then
  clear_s
  show_banner "Current System Performance is $(perf_type_handler $current_perf)"
  echo "Choose System Performance"
  option=$(gum choose --limit 1 "Ultra" "Performance" "Balance" "Powersave"  )
  handle_sys_perf $option
  
fi
