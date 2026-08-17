class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  version "0.1.0"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_arm64.tar.gz"
      sha256 "5a4db3e6341877787580d102cdcc10a114d4e4f8d3d8b5884a2173496a32d6d2"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_amd64.tar.gz"
      sha256 "c5c3478808849dab2842bc62fcc575ab9c189bb8adb1d1462f0815da4eeb04a7"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_arm64.tar.gz"
      sha256 "011e6bddd0d8aab54d38516cc7f17ca5c15f5f9e2c72ca5dc96c2ac123565938"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_amd64.tar.gz"
      sha256 "c26e741690084fcd9ce6278cc812e4e01b46a95a79dbe729b1585cba10144860"
    end
  end

  def install
    libexec.install "python"
    libexec.install "lazydeck" => "lazydeck-bin"

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

  test do
    assert_path_exists libexec/"lazydeck-bin"
    assert_path_exists libexec/"python/cli.py"
  end
end
