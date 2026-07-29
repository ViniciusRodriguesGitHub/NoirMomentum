# Noir Momentum — Protótipo 01

Protótipo 2D feito em Godot 4.7.1 com visual procedural. Não utiliza imagens
externas: o personagem, a cidade, a fumaça, as luzes e as partículas são
desenhados pelo próprio jogo.

As luzes espalhadas pela fase podem ser coletadas e aparecem no contador do
HUD. Algumas ficam em plataformas acessíveis apenas com salto carregado,
segundo salto ou salto na parede. A ambientação e os efeitos sonoros também
são sintetizados proceduralmente pelo jogo.

A fase termina no portão à direita somente após coletar todas as luzes. O HUD
mostra o tempo da tentativa e o melhor tempo registrado durante a sessão.

## Controles

- `A` / `D` ou setas: caminhar.
- Dois toques na mesma direção: correr.
- `S` ou seta para baixo durante a corrida: deslizar deitado.
- `S` ou seta para baixo parado: carregar o salto alto; solte para pular.
- Segure `S` ou seta para baixo e use uma direção: andar agachado.
- Direção contrária durante a corrida: derrapar e mudar de direção.
- Toque em `Espaço`: salto curto; segure para alcançar a altura normal.
- `Espaço` junto à parede: quicar para o lado oposto.
- `R`: reiniciar a fase.
- Controle: analógico ou direcional; botão inferior para pular.

## Como abrir

Abra o arquivo `project.godot` no Gerenciador de Projetos da Godot ou execute:

```powershell
godot --editor --path "$env:USERPROFILE\GodotProjects\NoirMomentum"
```

Dentro da Godot, pressione `F6` ou `F5` para executar.

## Jogar no navegador

Após a publicação do workflow `Publicar jogo no GitHub Pages`, o jogo fica
disponível em:

https://viniciusrodriguesgithub.github.io/NoirMomentum/

O workflow exporta automaticamente a versão Web com Godot 4.7.1 sempre que
uma alteração chega à branch `main`.

### Publicar no itch.io

O workflow manual `Publicar jogo no itch.io` exporta a mesma versão HTML5 e
envia o diretório com `butler`. Antes de executá-lo, crie uma página do tipo
HTML Game no itch.io e configure no repositório:

- secret `BUTLER_API_KEY`;
- variável `ITCH_USERNAME`;
- variável `ITCH_GAME` com o identificador da página.

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
