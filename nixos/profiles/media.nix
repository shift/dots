{
  config,
  flake,
  modulesPath,
  lib,
  pkgs,
  ...
}:
let
  MainDir = "/export/downloads";
in
{

  services.nfs.server = {
    enable = true;
    # fixed rpc.statd port; for firewall
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
  };
  services.nfs.server.exports = ''
    /export/media         192.168.1.202(rw,fsid=0,no_subtree_check,insecure)
    /export/media/movies  192.168.1.202(rw,nohide,insecure,no_subtree_check,insecure)
    /export/media/tv  192.168.1.202(rw,nohide,insecure,no_subtree_check,insecure)
    /export/media/photos  192.168.1.202(rw,nohide,insecure,no_subtree_check,insecure)
    /export/media/ebooks  192.168.1.202(rw,nohide,insecure,no_subtree_check,insecure)
  '';

  networking.firewall = {
    enable = true;
    # for NFSv3; view with `rpcinfo -p`
    allowedTCPPorts = [
      22
      111
      2049
      4000
      4001
      4002
      20048
      6789
      6767
      8096
      7878
      8989
    ];
    allowedUDPPorts = [
      111
      2049
      4000
      4001
      4002
      20048
    ];
  };

  users.groups.multimedia = { };
  services = {
    jellyfin = {
      enable = true;
      group = "multimedia";
    };
    nzbget = {
      enable = true;
      group = "multimedia";
      settings = {
        MainDir = "/export/downloads";
        DestDir = "${MainDir}/completed";
        InterDir = "${MainDir}/intermediate";
        NzbDir = "${MainDir}/nzb";
        QueueDir = "${MainDir}/queue";
        TempDir = "${MainDir}/tmp";
        WebDir = "${pkgs.nzbget}/share/nzbget/webui";
        ScriptDir = "${MainDir}/scripts";
        LockFile = "/export/downloads/nzbget.lock";
        LogFile = "/export/downloads/nzbget.log";
        "Server1.Active" = "yes";
        "Server1.Name" = "eweka";
        "Server1.Level" = 0;
        "Server1.Optional" = "no";
        "Server1.Group" = 0;
        "Server1.Host" = "$(cat ${config.sops.secrets."nzbget/host".path}}";
        "Server1.Port" = 563;
        "Server1.Username" = "$(cat ${config.sops.secrets."nzbget/username".path}}";
        "Server1.Password" = "$(cat ${config.sops.secrets."nzbget/password".path}}";
        "Server1.JoinGroup" = "no";
        "Server1.Encryption" = "yes";
        "Server1.Connections" = 20;
        "Server1.Retention" = 4412;
        "Server1.IpVersion" = "auto";
        ControlIP = "0.0.0.0";
        ControlPort = "6789";
        FormAuth = "no";
        SecureControl = "no";
        SecurePort = "6791";
        AuthorizedIP = "127.0.0.1";
        CertCheck = "yes";
        UMask = "1000";
        AppendCategoryDir = "yes";
        NzbDirInterval = 5;
        NzbDirFileAge = 60;
        DupeCheck = "yes";
        FlushQueue = "yes";
        ContinuePartial = "yes";
        PropagationDelay = 0;
        ArticleCache = 0;
        DirectWrite = "yes";
        WriteBuffer = 0;
        FileNaming = "auto";
        ReorderFiles = "yes";
        PostStrategy = "balanced";
        DiskSpace = 2500;
        NzbCleanupDisk = "yes";
        KeepHistory = 30;
        FeedHistory = 7;
        SkipWrite = "no";
        RawArticle = "no";
        ArticleRetries = 3;
        ArticleInterval = 10;
        ArticleTimeout = 60;
        UrlRetries = 3;
        UrlInterval = 10;
        UrlTimeout = 60;
        RemoteTimeout = 90;
        DownloadRate = 0;
        UrlConnections = 4;
        UrlForce = "yes";
        MonthlyQuota = 0;
        QuotaStartDay = 1;
        DailyQuota = 0;
        TimeCorrection = 0;
        UpdateInterval = "200";
        CrcCheck = "yes";
        ParCheck = "auto";
        ParRepair = "yes";
        ParScan = "extended";
        ParQuick = "yes";
        ParBuffer = 16;
        ParThreads = 0;
        ParIgnoreExt = ".sfv, .nzb, .nfo";
        ParRename = "yes";
        RarRename = "yes";
        DirectRename = "no";
        HealthCheck = "park";
        ParTimeLimit = 0;
        ParPauseQueue = "no";
        Unpack = "yes";
        DirectUnpack = "no";
        UnpackPauseQueue = "yes";
        UnpackCleanupDisk = "yes";
        UnrarCmd = "unrar";
        SevenZipCmd = "7z";
        ExtCleanupDisk = ".par2, .sfv";
        UnpackIgnoreExt = ".cbr";
      };

    };
    sonarr = {
      enable = true;
      group = "multimedia";
      dataDir = "/export/config/sonarr/";
    };
    radarr = {
      enable = true;
      group = "multimedia";
      dataDir = "/export/config/radarr/";
    };
    #bazarr = { enable = true; group = "multimedia"; };
    #prowlarr = { enable = true; };
  };

}
