{ pkgs ? import <nixos-unstable> {} } :
{
  foo = pkgs.mkShell {
    packages = [
      pkgs.ninja
      pkgs.meson
      pkgs.pkg-config
      pkgs.gcc
      pkgs.rtmidi
      pkgs.alsa-lib
      (pkgs.python311.withPackages (python-pkgs: with python-pkgs; [
        pip
        setuptools
        wheel
        ninja
      ]))
    ];

    shellHook = ''
      # Expose ALSA and RtMidi dynamic libraries to Python C extensions
      export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
        pkgs.alsa-lib
        pkgs.rtmidi
        pkgs.stdenv.cc.cc.lib
      ]}:$LD_LIBRARY_PATH"

      # Re-create .venv if missing
      if [ ! -d ".venv" ]; then
        echo "Creating Python virtual environment in .venv..."
        python3 -m venv .venv
      fi

      # Activate virtual environment
      source .venv/bin/activate

      # Upgrade pip inside venv
      pip install --upgrade pip

      # Install dependencies and project using system site-packages
      if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
      fi
      
      if [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        pip install -e .
      fi

      echo now run: python3 -m ht_cli.ht_cli 
    '';
  };
}
