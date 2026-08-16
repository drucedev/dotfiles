# Explicit source order — zinit must load before completions compile,
# tool integrations follow, aliases last. Machine-specific extras from the
# stow packages (mac/linux/work) come after everything so they can override.
for module in env plugin completion history tool alias; do
  source "$ZDOTDIR/$module.zsh"
done

for extra in "${(L)$(uname -s)}.zsh" work.zsh; do
  [[ -f "$ZDOTDIR/$extra" ]] && source "$ZDOTDIR/$extra"
done
