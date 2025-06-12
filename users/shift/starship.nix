{
  programs.starship = {
    enable = true;
    settings = {
      # Global config
      add_newline = true;
      scan_timeout = 30;
      command_timeout = 500;

      # Character config
      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      # Battery config for laptop
      battery = {
        full_symbol = "🔋";
        charging_symbol = "⚡️";
        discharging_symbol = "💀";
        display = [
          {
            threshold = 10;
            style = "red bold";
          }
          {
            threshold = 30;
            style = "yellow bold";
          }
        ];
      };

      # Directory config
      directory = {
        truncation_length = 5;
        truncate_to_repo = true;
        fish_style_pwd_dir_length = 1;
        read_only = " 🔒";
      };

      # Git configuration
      git_branch = {
        symbol = "🌱 ";
        truncation_length = 20;
        truncation_symbol = "...";
        style = "bold purple";
      };

      git_commit = {
        commit_hash_length = 8;
        style = "bold green";
      };

      git_state = {
        format = "[\($state( $progress_current of $progress_total)\)]($style) ";
        cherry_pick = "[🍒 PICKING](bold red)";
        rebase = "[📥 REBASING](bold blue)";
        merge = "[🔗 MERGING](bold yellow)";
      };

      git_status = {
        conflicted = "🏮 ";
        ahead = "🏃 ";
        behind = "😰 ";
        diverged = "😵 ";
        untracked = "🤷 ";
        stashed = "📦 ";
        modified = "📝 ";
        staged = "➕ ";
        renamed = "👅 ";
        deleted = "🗑 ";
      };

      # Language versions
      nodejs = {
        symbol = "⬢ ";
        style = "bold green";
        detect_files = [
          "package.json"
          "node_modules"
        ];
      };

      python = {
        symbol = "🐍 ";
        style = "bold yellow";
        detect_files = [
          "requirements.txt"
          "pyproject.toml"
          "setup.py"
        ];
        python_binary = [
          "python3"
          "python"
        ];
      };

      rust = {
        symbol = "🦀 ";
        style = "bold red";
        detect_files = [ "Cargo.toml" ];
      };

      golang = {
        symbol = "🐹 ";
        style = "bold cyan";
        detect_files = [
          "go.mod"
          "go.sum"
          "go.work"
          "main.go"
        ];
      };

      nix_shell = {
        symbol = "❄️ ";
        style = "bold blue";
        format = "via [$symbol$state( \($name\))]($style) ";
      };

      # System info
      memory_usage = {
        symbol = "🧠 ";
        style = "bold dimmed white";
        threshold = 75;
        disabled = false;
        format = "$symbol[$ram( | $swap)]($style) ";
      };

      cmd_duration = {
        min_time = 2000;
        format = "took [$duration]($style) ";
        style = "yellow bold";
        show_milliseconds = false;
      };

      # Editor status
      shlvl = {
        symbol = "↕️ ";
        style = "bold cyan";
        disabled = false;
      };

      shell = {
        fish_indicator = "🐟";
        bash_indicator = "💻";
        zsh_indicator = "💻";
        unknown_indicator = "mystery shell";
        style = "cyan bold";
        disabled = false;
      };

      # Custom format
      format = "$username$hostname$shlvl$directory$git_branch$git_commit$git_state$git_status$nodejs$python$rust$golang$nix_shell$cmd_duration$battery$line_break$jobs$time$character";

      # Time
      time = {
        disabled = false;
        format = "🕙 [$time]($style) ";
        style = "bold yellow";
        time_format = "%T";
      };
    };
  };
}
