#!/bin/bash
#Install zsh curl
sudo apt install zsh curl
echo "zsh and curl installed"

#Install Oh My ZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
echo "Installed Oh My ZSH"

#Install PowerLevel10k Theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
echo "Installed PowerLevel10K"

#Install zsh-autosuggestion
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

#
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting


#Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
echo "Installed fzf"

#Remove old configs and link to git repo one's
rm ~/.bash*
ln -s ~/mav_linux_conf/.bash_profile ~/.bash_profile
ln -s ~/mav_linux_conf/.bashrc ~/.bashrc
rm ~/.zshrc
ln -s ~/mav_linux_conf/.zshrc ~/.zshrc
rm ~/.p10k.zsh
ln -s ~/mav_linux_conf/.p10k.zsh ~/.p10k.zsh
ln -s ~/mav_linux_conf/.ssh/config ~/.ssh/config
echo "Links created" 
