class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.3.0/lazydeck_0.3.0_darwin_arm64.tar.gz"
      sha256 "d57f602ff03b70ae9960054bcd46b1263ed9588f457dc8c38ef46edc11d9eefb"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.3.0/lazydeck_0.3.0_darwin_amd64.tar.gz"
      sha256 "3dc0959227d6a13e7ad98a8e42f12ed5a9c71ed1595e21c5827bf06a17fe2761"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.3.0/lazydeck_0.3.0_linux_arm64.tar.gz"
      sha256 "f6df709b18cc6c561689e9f57a1fcab4466b8212c59677025553b52fddda2d06"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.3.0/lazydeck_0.3.0_linux_amd64.tar.gz"
      sha256 "2ed7becbefefec3ef91c2f03cee0ff326a93099b79ae2476b26754cfd9220330"
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
