class Lazydeck < Formula
  desc "Terminal UI for managing a fleet of Steam devkits"
  homepage "https://github.com/KevinTCoughlin/lazydeck"
  version "0.1.0"
  license "MIT"

  depends_on "uv"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_arm64.tar.gz"
      sha256 "d9aac2618f985e7cb5414538c8cf4729f90b29f30e98d25d95b149388fe3b769"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_darwin_amd64.tar.gz"
      sha256 "0c893009f97322e61e43ef16b1d2ee768becef4a4cca085590798d4bc1fa9efe"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_arm64.tar.gz"
      sha256 "2052cd5c47d94ee70da69e3075e5661762862ddd504eec672cd4818220fe9f04"
    else
      url "https://github.com/KevinTCoughlin/lazydeck/releases/download/v0.1.0/lazydeck_0.1.0_linux_amd64.tar.gz"
      sha256 "4322ca8c6998dc51fa079f88c352759747b109f4852388a7cf6a7bc2a91ccb15"
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
