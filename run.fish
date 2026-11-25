#!/usr/bin/env fish
cd (dirname (status filename))
if not test -f .venv/bin/activate.fish
    echo 'Create the virtual environment first: python -m venv .venv'
    exit 1
end
source .venv/bin/activate.fish
python main.py
