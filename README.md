# Noir Momentum — Protótipo 01

Protótipo 2D feito em Godot 4.7.1 com visual procedural. Não utiliza imagens
externas: o personagem, a cidade, a fumaça, as luzes e as partículas são
desenhados pelo próprio jogo.

## Controles

- `A` / `D` ou setas: caminhar.
- Dois toques na mesma direção: correr.
- `S` ou seta para baixo durante a corrida: deslizar deitado.
- Direção contrária durante a corrida: derrapar e mudar de direção.
- `Espaço`: pular.
- `R`: reiniciar a fase.
- Controle: analógico ou direcional; botão inferior para pular.

## Como abrir

Abra o arquivo `project.godot` no Gerenciador de Projetos da Godot ou execute:

```powershell
godot --editor --path "$env:USERPROFILE\GodotProjects\NoirMomentum"
```

Dentro da Godot, pressione `F6` ou `F5` para executar.

## VS Code

O projeto inclui configuração pronta para a extensão oficial da comunidade
Godot Tools:

- `F5`: executa o projeto com o depurador de GDScript.
- `Terminal > Run Task > Godot: Abrir editor`: abre o editor da Godot.
- `Terminal > Run Task > Godot: Executar jogo`: inicia o jogo.
- `Terminal > Run Task > Godot: Testar projeto`: executa os testes automáticos.

Para configurar Git, GitHub e VS Code pela primeira vez, execute no PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
& ".\Configurar-GitHub-VSCode.ps1"
```

Depois da configuração inicial, abra o projeto com:

```powershell
code "$env:USERPROFILE\GodotProjects\NoirMomentum"
```

## Estrutura

- `scenes/main.tscn`: composição da fase.
- `scenes/player/player.tscn`: personagem e câmera.
- `scripts/player.gd`: máquina de estados e movimentação.
- `scripts/noir_world.gd`: cenário, plataformas e colisões.
- `scripts/world_fx.gd`: fumaça, poeira e partículas.
- `scripts/hud.gd`: informações e controles na tela.
- `scripts/main.gd`: inicialização, comandos e integração dos sistemas.
