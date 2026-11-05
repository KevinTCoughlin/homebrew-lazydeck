class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.2.2/lazydeck_0.2.2_darwin_arm64.tar.gz"
      sha256 "8319a2af9f86b6c566d73f2ddaa3456ede8ed8bea0ba90e833d652a62d0380ae"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.2.2/lazydeck_0.2.2_darwin_amd64.tar.gz"
      sha256 "2ef5c9d5185f80950b76f1611e0ace9f73c69de219382ecd3f0e632997b28014"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.2.2/lazydeck_0.2.2_linux_arm64.tar.gz"
      sha256 "e2914dfa700fb4add36e2f31e3b75b3109e04b105d51a2a5618efa835dbc2a18"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.2.2/lazydeck_0.2.2_linux_amd64.tar.gz"
      sha256 "aa669479a550ca4e0727100632c445bcedd2dd2fb64c2b8ab5fb653e50135557"
    end
  end

  def install
    libexec.install "python"
    libexec.install "lazydeck" => "lazydeck-bin"

    # Upstream releases starting after v0.1.0 bundle a man page and shell
    # completions in the archive; guard on presence so this formula keeps
    # working for both older and newer release layouts.
    man1.install "docs/lazydeck.1" if File.exist?("docs/lazydeck.1")
    bash_completion.install "completions/lazydeck.bash" => "lazydeck" if File.exist?("completions/lazydeck.bash")
    zsh_completion.install "completions/_lazydeck" if File.exist?("completions/_lazydeck")
    fish_completion.install "completions/lazydeck.fish" if File.exist?("completions/lazydeck.fish")

    (bin/"lazydeck").write <<~EOS
      #!/bin/sh
      set -eu
      runtime="#{var}/lazydeck/python"
      # Refresh the bridge on every version change: an upgrade must not keep
      # running the previous release's cli.py against the new binary.
      if [ "$(cat "$runtime/.lazydeck-version" 2>/dev/null)" != "#{version}" ]; then
        rm -rf "$runtime"
        mkdir -p "$runtime"
        cp -R "#{libexec}/python/." "$runtime/"
        echo "#{version}" > "$runtime/.lazydeck-version"
      fi
      export LAZYDECK_PYTHON_DIR="$runtime"
      export UV_PROJECT_ENVIRONMENT="#{var}/lazydeck/venv"
      exec "#{libexec}/lazydeck-bin" "$@"
    EOS
  end

  # Mirrors upstream's packaging/systemd/user/lazydeck-serve.service: the
  # local HTTP API used by Godot/Unity editor integrations. Not started
  # automatically; opt in with `brew services start lazydeck`.
  service do
    run [opt_bin/"lazydeck", "serve"]
    keep_alive crashed: true
    log_path var/"log/lazydeck.log"
    error_log_path var/"log/lazydeck.error.log"
  end

  test do
    assert_path_exists libexec/"lazydeck-bin"
    assert_path_exists libexec/"python/cli.py"
  end
end
