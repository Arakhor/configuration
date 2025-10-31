export-env {
  if ( which starship | is-empty ) { return }

  $env.config.render_right_prompt_on_last_line = true

  $env.STARSHIP_SESSION_KEY = (random chars -l 16)
  $env.STARSHIP_SHELL = "nu"

  # HACK:
  #
  # Render character module separately from prompt
  # this allows vi-mode indicator to work on nushell
 
  def _indicator [
      --vicmd (-v)
  ] {
      $env.STARSHIP_SHELL = "zsh"
      let status = $"--status=( $env.LAST_EXIT_CODE )"

      if $vicmd {
          starship module character --keymap vicmd $status 
      } else {
          starship module character $status
      }
  }

  def --wrapped _prompt [...rest] {
      (
        ^starship prompt
          $"--cmd-duration=( $env.CMD_DURATION_MS )"
          $"--status=( $env.LAST_EXIT_CODE )"
          $"--terminal-width=( (term size).columns )"
          $"--jobs=( job list | length )"
          ...$rest
      ) | str replace (_indicator) "" 
  }

  $env.PROMPT_INDICATOR = {|| _indicator }
  $env.PROMPT_INDICATOR_VI_INSERT = {|| _indicator }
  $env.PROMPT_INDICATOR_VI_NORMAL = {|| _indicator -v }
  $env.PROMPT_MULTILINE_INDICATOR = {|| _prompt --continuation  }

  # $env.TRANSIENT_PROMPT_INDICATOR = ""
  # $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ""
  # $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ""
  # $env.TRANSIENT_PROMPT_COMMAND = {|| _indicator }
  # $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| starship module time }

  $env.PROMPT_COMMAND = {|| _prompt }
  $env.PROMPT_COMMAND_RIGHT = {|| _prompt --right }
}
