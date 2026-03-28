#!/usr/bin/env python3
"""Launch coffee-break.sh in a real PTY so cursor animation codes render correctly."""
import pty, os, sys

script_dir = os.path.dirname(os.path.abspath(__file__))
script = os.path.join(script_dir, 'coffee-break.sh')
duration = sys.argv[1] if len(sys.argv) > 1 else '300'

pty.spawn(['/bin/bash', script, duration])
