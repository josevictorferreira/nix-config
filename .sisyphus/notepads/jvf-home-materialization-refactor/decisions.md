# Decisions

## T4: No home import from wrappers
Wrappers must NOT import `self.modules.nixos.home` because both hosts already
import it. Duplicate import causes `jvf.home._compiled is already declared`.
The translation layer only needs the home OPTIONS to exist (which they do
from the host import).
