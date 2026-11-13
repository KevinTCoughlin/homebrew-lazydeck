class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.1/lazydeck_0.4.1_darwin_arm64.tar.gz"
      sha256 "7b7ac19be9b13ec77864c9ac682288381002be654e083808bf87a620790ab649"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.1/lazydeck_0.4.1_darwin_amd64.tar.gz"
      sha256 "5a465ccdd32c3527d94c9d8209b68be9f8482ec9a021b24b86c6b12cae81c098"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.1/lazydeck_0.4.1_linux_arm64.tar.gz"
      sha256 "d319332cc87d996236749962f9db913c476688f708d5a8e2ee1a289978aa3d6a"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.4.1/lazydeck_0.4.1_linux_amd64.tar.gz"
      sha256 "e0ca1546e0a2810479da6daa86e17a1db694d1d95678200dc86cb6c1f4487aef"
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
