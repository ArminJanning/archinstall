This script installs Arch Linux to 


FAQ:

F: Why is this public?
Q: That allows me to run curl https://raw.githubusercontent.com/ArminJanning/archinstall/refs/heads/main/archinstall.sh > archinstall.sh

F: Isn't curl | sh bad practice?
Q: Yes. Yes it is.

F: Why is this the only repo on your account?
Q: This is a mirror of a repo which I run on my selfhosted Gitea instance. Publicizing this makes it easier to test and run on systems outside my local network.

F: What makes this script different from all the other archinstall scripts out there?
Q: Not much. I just thought it would be fun to create this one.

F: Should I use this?
Q: Probably not. This script makes a lot of assumptions (allthough it does check for stuff like firmware) and integrates some of my preferences like having multiple Kernels.
Besides that, I do not plan on supporting this project longterm and rarely test it.