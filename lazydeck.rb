class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  version "0.1.0"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_arm64.tar.gz"
      sha256 "898bded6d545a71a940b43816dc8f52256a70013c4e3ad0ab671a5a0f76be197"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_amd64.tar.gz"
      sha256 "6518c845b6ad8dc02c83ccf733fb0f76b391135619e1563316401c0d80e52872"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_arm64.tar.gz"
      sha256 "98d6eb59f581dc76309efe9c55665518947c046c57a59c0e347a3fd23d8a6e0b"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_amd64.tar.gz"
      sha256 "77b9ff5d78d6ec0c6e42833cab20071ce5d798a8e6a1dcf75fba008dd0d4ebaf"
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
      if [ ! -f "$runtime/pyproject.toml" ]; then
        mkdir -p "$runtime"
        cp -R "#{libexec}/python/." "$runtime/"
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
    keep_alive false
    log_path var/"log/lazydeck/serve.log"
    error_log_path var/"log/lazydeck/serve.log"
  end

  test do
    assert_path_exists libexec/"lazydeck-bin"
    assert_path_exists libexec/"python/cli.py"
  end
end
