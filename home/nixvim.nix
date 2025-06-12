{
  config,
  inputs,
  pkgs,
  ...
}:
{
  programs.nixvim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    wrapRc = true;
    clipboard.providers.wl-copy.enable = true;
    plugins = {
      transparent = {
        enable = true;
      };
      web-devicons.enable = true;
      yazi.enable = true;
      coq-nvim = {
        enable = true;
        settings = {
          auto_start = true;
          completion = {
            always = true;
          };
          keymap = {
            recommended = true;
          };
        };
      };
      blink-cmp = {
        enable = true;
      };
      copilot-lua = {
        enable = false;
      };
      lsp-format = {
        enable = true;
      };
      telescope = {
        enable = true;
        extensions = {
          #file_browser = {
          #  enable = true;
          # hijackNetrw = true;
          #};
          # frecency.enable = true;
          fzf-native = {
            enable = true;
          };
          undo = {
            enable = true;
          };
        };
      };
      auto-session = {
        enable = true;
      };
      which-key = {
        enable = true;
      };
      yanky = {
        enable = true;
      };
      comment = {
        enable = true;
      };
      neo-tree = {
        enable = true;
        filesystem = {
          filteredItems = {
            hideDotfiles = false;
            # hideHidden = true;
            neverShowByPattern = [
              "__pycache__"
              "node_modules"
              ".git"
              ".DS_Store"
            ];
          };
        };
      };
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "│";
            tab_char = "│";
          };
          exclude = {
            filetypes = [
              "help"
              "dashboard"
              "neo-tree"
              "Trouble"
              "trouble"
              "notify"
              "toggleterm"
            ];
          };
        };
      };
      notify = {
        enable = true;
      };
      barbecue = {
        enable = true;
      };
      #none-ls = {
      #  enable = true;
      #  enableLspFormat = true;
      #};
      leap = {
        enable = true;
      };
      neogit = {
        enable = true;
      };
      neogen = {
        enable = true;
      };
      multicursors = {
        enable = true;
      };
      todo-comments = {
        enable = true;
      };
      markdown-preview = {
        enable = true;
      };
      harpoon = {
        enable = true;
        enableTelescope = true;
      };
      easyescape = {
        enable = true;
      };
      # gitblame.enable = true;
      # gitsigns.enable = true;
      illuminate = {
        enable = true;
      };
      # cursorline.enable = true;
      fidget = {
        enable = true;
      };
      lint = {
        enable = true;
      };
      git-worktree = {
        enable = true;
      };
      # fugitive.enable = true;
      flash = {
        enable = true;
      };
      noice = {
        enable = true;
      };
      treesitter-refactor = {
        enable = true;
      };
      treesitter = {
        enable = true;
      };
      lsp = {
        enable = true;
        servers = {
          nixd = {
            enable = true;
          };
          gopls = {
            enable = true;
          };
          clangd = {
            enable = true;
          };
          bashls = {
            enable = true;
          };
          jsonls = {
            enable = true;
          };
          ts_ls = {
            enable = true;
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    rubyPackages.htmlbeautifier
    wl-clipboard-rs
    vscode-fhs
  ];
}
