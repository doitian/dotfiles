dotfiles:
  # All repos are created in .dotfiles/NAME
  repos:
    public:
      git: https://github.com/doitian/dotfiles-public.git
      # location: .dotfiles/repos/public
    private:
      git: git@github.com:doitian/dotfiles-private.git
      private: True
    on-my-zsh:
      git: https://github.com/robbyrussell/oh-my-zsh.git
      location: .oh-my-zsh
    # location: .dotfiles/repos/private

    # download_archive:
    #   archive: http://example.com/archive.zip
    # download_single:
    #   single: http://example.com/single
