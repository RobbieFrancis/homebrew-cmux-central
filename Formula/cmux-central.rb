class CmuxCentral < Formula
  desc "Local-first P2P mesh dashboard for CMUX workspaces"
  homepage "https://github.com/RobbieFrancis/cmux-central"
  url "https://github.com/RobbieFrancis/cmux-central/archive/v0.1.0.tar.gz"
  sha256 "8cc09dbd212bb2737ee8a1687a525cead6bd3de62f0925e948724df5f8a40c08"
  license "MIT"

  depends_on "node@22"
  depends_on :macos

  def install
    mkdir_p buildpath/"corepack-bin"
    system "corepack", "enable", "--install-directory", buildpath/"corepack-bin"
    ENV.prepend_path "PATH", buildpath/"corepack-bin"
    system "corepack", "prepare", "pnpm@latest", "--activate"

    system "pnpm", "install", "--frozen-lockfile"

    system "pnpm", "--filter", "@cmux-central/shared", "build"
    system "pnpm", "--filter", "@cmux-central/client", "build"
    system "pnpm", "--filter", "@cmux-central/dashboard", "build"
    system "pnpm", "--filter", "@cmux-central/agent", "build"

    libexec.install Dir["*"]
    libexec.install ".npmrc" if File.exist?(".npmrc")

    (bin/"cmux-central-agent").write <<~SH
      #!/bin/bash
      exec "#{Formula["node@22"].opt_bin}/node" "#{libexec}/packages/agent/dist/cli.js" "$@"
    SH

    (bin/"cmux-central-bg").write <<~SH
      #!/bin/bash
      exec "#{Formula["node@22"].opt_bin}/node" "#{libexec}/packages/agent/scripts/agent-start.mjs" "$@"
    SH
  end

  def caveats
    <<~EOS
      CMUX Central has been installed!

      To start the agent in a CMUX workspace:
        cmux-central-bg

      To run the agent directly:
        cmux-central-agent start

      Configuration is stored at:
        ~/.cmux-central/config.json

      For auto-start on CMUX launch, add to your ~/.zshrc:
        if command -v cmux >/dev/null 2>&1 && [ -z "$CMUX_WORKSPACE_ID" ]; then
          cmux-central-bg &>/dev/null &
          disown
        fi

      Dashboard: http://localhost:4200

      Note: CMUX must be installed separately.
    EOS
  end

  test do
    assert_match "CMUX Central Agent", shell_output("#{bin}/cmux-central-agent --help 2>&1", 1)
  end
end
