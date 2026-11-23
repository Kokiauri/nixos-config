{ config, pkgs, inputs, lib, ... }:

let
  legcordPatched = pkgs.legcord.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        url = "https://github.com/Legcord/Legcord/commit/133df0f6209e44af15b360a6adda9a9d6fa6e146.patch";
        hash = "sha256-+Pop9+1Nf3T7DPQ+QbXvZ04T2hQqkQhPbevNE7JjBog=";
      })
    ];
  });

  # Vim mode for LibreOffice; menu entry restricted to Writer (upstream also adds it to Draw/Impress)
  vibreoffice = pkgs.stdenvNoCC.mkDerivation {
    pname = "vibreoffice";
    version = "0.1.4";
    src = pkgs.fetchFromGitHub {
      owner = "seanyeh";
      repo = "vibreoffice";
      rev = "b8d60b1ae75e169c6273258f8e0b1e09cea9f7af";
      hash = "sha256-X3ATwW1+QNOV42g9MwaUi4cjm4j1gBRoKG9zm14Wn/c=";
    };
    nativeBuildInputs = [ pkgs.zip ];
    postPatch = ''
      substituteInPlace extension/template/AddonUI.xcu \
        --replace-fail ',com.sun.star.drawing.DrawingDocument,com.sun.star.presentation.PresentationDocument' ""
      patchShebangs compile.sh

      # LibreOffice 26.8+ hands KeyEvent.KeyChar to Basic as a number, which upstream
      # treats as a count digit -> "Overflow" on every key. Normalise it to a string.
      sed -i 's/oEvent\.KeyChar/eventChar(oEvent)/g' src/vibreoffice.vbs
      cat >> src/vibreoffice.vbs <<'EOF'

      Function eventChar(oEvent) As String
          If VarType(oEvent.KeyChar) = 8 Then
              eventChar = oEvent.KeyChar
          Else
              eventChar = Chr(oEvent.KeyChar)
          End If
      End Function
      EOF
    '';
    buildPhase = "VIBREOFFICE_VERSION=0.1.4 make extension";
    installPhase = "install -Dm644 dist/vibreoffice-0.1.4.oxt $out/vibreoffice.oxt";
  };
in
{
  home.username = "saponela";
  home.homeDirectory = "/home/saponela";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager
  # release notes for a list of state version changes in each release.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  imports = [
    inputs.lazyvim.homeManagerModules.default
    ./lazyvim.nix
  ];

  # The home.packages option allows you to install Nix packages into your
  # environment.
  services.kdeconnect = {
    enable = true;
    indicator = true;
  };
  systemd.user.services.kdeconnect.Install.WantedBy = [ "default.target" ];

  programs.claude-code = {
    enable = true;
    skills = {
      ponytail = "${inputs.ponytail-skill}/skills/ponytail";
      agent-browser = "${inputs.agent-browser-skill}/skills/agent-browser";
      python-best-practices = "${inputs.bigboss-claude-code}/.claude/skills/python-best-practices";
    };
  };
  # agent-browser's downloaded Chrome won't run on NixOS; use the Nix one
  home.sessionVariables.AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.google-chrome;
  home.packages = with pkgs; [
    # Development
    vscode
    jdk21_headless
    gcc # C compiler
    gnumake
    gdb
    git
    gh
    docker
    pnpm
    nodejs
    postman
    jupyter #machine learning class
    imagemagick # image & animated gif rendering for jupynvim
    chafa # terminal image fallback
    # ollama
    gnupg
    pinentry-tty
    gitui
    anydesk
    agent-browser 
    proton-vpn

  
    # Messaging
    telegram-desktop
    legcordPatched
    libnotify
    wl-clipboard
    nautilus
    ranger
    yazi
    ffmpegthumbnailer
    unar
    poppler-utils
    fd
    ripgrep
    fzf
    zoxide
    brightnessctl
    playerctl
    
    # Terminal & Shell
    ghostty
    kitty # fallback
    fish
    btop
    bat
    tmux
    
    # Tools
    fastfetch
    upower
    duf 
    cowsay
    obsidian
    anki
    obs-studio
    jp2a
    keymapper
    moonlight-qt
    mangohud
    pamixer
    pulseaudio
    paprefs
    blender #vTraining
    krita
    reco # voice recorder 
    wiremix

    # Misc
    flatpak
    libreoffice
    webcamoid
    
    # Music & Entertainment
    steam
    qbittorrent
    mpv
    google-chrome
    brave
    prismlauncher
    protonup-qt
    ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    ".config/btop".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/btop";
    ".config/fish".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/fish";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/kitty";
    ".config/ghostty".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/ghostty";
    # ghostty.desktop is DBusActivatable; the session bus only scans ~/.local/share, not the HM profile
    ".local/share/dbus-1/services/com.mitchellh.ghostty.service".source = "${pkgs.ghostty}/share/dbus-1/services/com.mitchellh.ghostty.service";
    ".config/Code/User/settings.json".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/vscode/User/settings.json";
    ".continue/config.yaml".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/continue/config.yaml";
    ".config/fastfetch".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/fastfetch";
    ".config/tmux/tmux.conf".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/tmux/tmux.conf";
    ".config/tmux/cheatsheet.txt".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/tmux/cheatsheet.txt";
    ".config/wireplumber".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/wireplumber";
    ".config/custom_scripts".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/custom_scripts";
    ".config/yazi".source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/yazi";
    ".cache/tmp/.keep".text = "";
    # ".config/spicetify".source = ./dotfiles/spicetify; # Managed by spicetify-nix
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/saponela/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Default Applications configuration
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "zen-beta.desktop" ];
      "x-scheme-handler/http" = [ "zen-beta.desktop" ];
      "x-scheme-handler/https" = [ "zen-beta.desktop" ];
    };
  };

  xdg.desktopEntries = {
    zen-beta = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen-beta %u";
      icon = "zen-browser";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "text/html" "text/xml" "application/xhtml+xml" "x-scheme-handler/http" "x-scheme-handler/https" ];
    };
  };

  gtk = {
    enable = true;
    iconTheme = {
      name = lib.mkDefault "Adwaita";
      package = lib.mkDefault pkgs.adwaita-icon-theme;
    };
  };

  # Writer: Tools → Add-Ons → "vibreoffice - Toggle Vi Mode". Reinstalls only when the .oxt changes.
  home.activation.installVibreoffice = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    marker="$HOME/.config/libreoffice/.vibreoffice-installed"
    if [ "$(cat "$marker" 2>/dev/null)" != "${vibreoffice}" ]; then
      $DRY_RUN_CMD ${pkgs.libreoffice}/bin/unopkg add -f -s ${vibreoffice}/vibreoffice.oxt \
        && $DRY_RUN_CMD mkdir -p "$(dirname "$marker")" \
        && $DRY_RUN_CMD sh -c "echo ${vibreoffice} > $marker" \
        || echo "vibreoffice: unopkg failed (is LibreOffice running?)"
    fi
  '';

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
