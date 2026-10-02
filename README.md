# dotfiles

## Usage
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/satnami/dotfiles/master/setup.sh)"
```

Safe to re-run: every step only installs what is missing. Existing files in `~` are
never overwritten by `setup.sh`; use `sh dot.sh import` for that (it keeps backups).

Preview what a run would do without changing anything:
```
DRY_RUN=1 sh ~/dotfiles/setup.sh
```

## Test
```
TBD
