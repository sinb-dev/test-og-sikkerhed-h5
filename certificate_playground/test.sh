isFedora=false
isUbuntu=false
if command -v lsb_release >/dev/null 2>&1; then
  distro=$(lsb_release -si 2>/dev/null | grep -Ei 'fedora|ubuntu' || true)
  if echo "$distro" | grep -qi fedora; then
    isFedora=true;
    
  elif echo "$distro" | grep -qi ubuntu; then
    isUbuntu=true;
  else
    echo "Unknown distribution: ${distro:-$(lsb_release -sd 2>/dev/null || echo 'none')}"
    exit 2
  fi
else
  echo "lsb_release not found"
  exit 3
fi

if [ "$isFedora" = true ]; then
	echo "This is Fedora";
elif ["$isUbuntu" = true ]; then
	echo "This is Ubuntu";
fi