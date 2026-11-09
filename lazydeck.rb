class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.0/lazydeck_0.4.0_darwin_arm64.tar.gz"
      sha256 "42e2d2934676831aede16d36bfcf32a3356419df45069287a6ad58ccad326edc"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.0/lazydeck_0.4.0_darwin_amd64.tar.gz"
      sha256 "37b607a5a69ec94ee9d66694bc2deb131147354d58541ad226742c4904b4f112"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.0/lazydeck_0.4.0_linux_arm64.tar.gz"
      sha256 "948e505ebc9ca97b91808d31d970273bc6e25f95f92eaf1aefeb1e5cdd74d13e"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.0/lazydeck_0.4.0_linux_amd64.tar.gz"
      sha256 "38764309312d98c9c112304988cc5129482fcb8c74c633ef38c528784b37fc13"
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
