path = require 'path'
helpers = require 'atom-linter'

lint = (editor) ->
  projectPath = (editor) ->
    editorPath = editor.getPath()
    projPath = atom.project.relativizePath(editorPath)[0]
    if projPath?
      return projPath
    null

  stdin = editor.getText()
  stream = 'both'

  ParseOutput = (editor, output) ->
    return [] if output.stderr == '** (Mix) The task "credo" could not be found'
    console.log output
    errors = []
    try
      for line in output.stdout.split("\n")
        matches = line.match(/^.*?:(\d+):?(\d+)?:\s(.*)/)
        line = (parseInt(matches[1]) - 1) if matches[1]
        col = (parseInt(matches[2]) - 1) if matches[2]
        col = 0 if isNaN(col)
        error = matches[3]
        errors.push {
          type: 'Warning',
          text: error,
          range: [[line, 0], [line, col+1]],
          filePath: editor.getPath()
        }
    catch e
      console.log "linter-elixir-credo error :"
      console.log e
    errors

  cwd = projectPath(editor)
  helpers.exec(atom.config.get('linter-elixir-credo.executablePath'), ['credo', '--read-from-stdin', '--format', 'flycheck'], {cwd, stdin, stream}).then (result) ->
    ParseOutput(editor, result)

linter =
  name: 'Credo'
  grammarScopes: [
    'source.elixir'
  ]
  scope: 'file'
  lintOnFly: true
  lint: lint

module.exports =
  config:
    command:
      type: 'string'
      title: 'Command'
      default: 'mix credo'
      description: '
        A linter for elixir using Credo
      '
      
    executablePath:
      type: 'string',
      default: 'mix',
      description: 'Absolute path to the mix executable on your system. Example: /usr/local/bin/mix , by default it checks for mix in your path'

  provideLinter: -> linter
