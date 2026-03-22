{ config, pkgs, ... }:
{
  services.easyeffects = {
    enable = true;
    preset = "Default";
  };

  xdg.configFile = {
    "easyeffects/output/Default.json".source = ./easyeffects/output/Default.json;
    "easyeffects/input/RNNoise.json".source = ./easyeffects/input/RNNoise.json;
    
    "easyeffects/irs/movie.irs".source = ./easyeffects/irs/movie.irs;
    "easyeffects/irs/music-balanced.irs".source = ./easyeffects/irs/music-balanced.irs;
    "easyeffects/irs/none.irs".source = ./easyeffects/irs/none.irs;
  };
}
