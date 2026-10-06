<p align="center">
  <img src="docs/images/icon.png" width="128" alt="Ícone do Melatonin">
</p>

<h1 align="center">Melatonin</h1>

<p align="center">
  <b>Feche a tampa. Seus agentes continuam trabalhando.</b><br>
  Um pequeno app de barra de menus para macOS que mantém seu MacBook acordado com a tampa fechada —<br>
  na bateria, sem monitor externo — enquanto o Claude Code, o Codex e companhia terminam o trabalho.
</p>

<p align="center">
  <a href="https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg"><b>Baixar</b></a> ·
  <a href="https://jugol.github.io/Melatonin/">Site</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.ar.md">العربية</a> ·
  <a href="README.hi.md">हिन्दी</a> ·
  <a href="README.id.md">Bahasa Indonesia</a>
</p>

<p align="center">
  <img src="docs/images/notch-expanded-on.png" width="640" alt="Melatonin expandido no notch">
</p>

## Por quê?

Você começa uma tarefa longa no Claude Code, fecha a tampa e sai. O macOS entra em repouso e a execução morre no meio do caminho.

Apps para manter o Mac acordado, como `caffeinate`, KeepingYouAwake e a maioria dos seus primos, usam asserções de energia (power assertions), e o macOS ignora essas asserções assim que a tampa fecha. A única coisa que realmente impede o repouso ao fechar a tampa é `pmset disablesleep`, e isso exige root. O Melatonin encapsula esse comando em uma pequena ferramenta auxiliar com privilégios e travas de segurança rígidas, e coloca o interruptor onde você vai ver: no notch.

## Recursos

- **Mora no seu notch.** Quando o Melatonin está ativado, uma lâmpada de luz quente brilha ao lado da câmera mostrando o tempo restante. Passe o ponteiro por cima para abrir todos os controles. Em telas sem notch, a pílula fica pendurada na barra de menus.
- **Interruptor na barra de menus.** Só o contorno de uma lua crescente: seu Mac vai dormir. Lua crescente com uma lâmpada âmbar: ele fica acordado.
- **Timers.** 1, 2, 4 ou 8 horas, ou até você desativar.
- **Lua, auto, lâmpada.** Um único seletor abaixo da lâmpada: **Desativado** deixa o Mac dormir, **Auto** o mantém acordado só enquanto os agentes trabalham e **Ativado** o mantém acordado até o timer acabar; depois volta ao modo anterior.
- **Automático com agentes de IA.** Fica acordado só enquanto um agente está realmente trabalhando: Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI, Cursor Agent, Amp, Goose ou Crush. A detecção observa a atividade de CPU em toda a árvore de processos de cada agente, então um agente parado no prompt não conta. Ele também lê os registros de sessão do Claude Code e do Codex, então uma resposta longa do modelo, um comando silencioso ou um subagente em segundo plano também contam como trabalho. Agentes iniciados pelo T3 Code contam como T3 Code.
- **Manter conexão.** Se a internet cair enquanto o Melatonin mantém seu Mac acordado, por exemplo quando você fecha a tampa e sai do Wi-Fi do escritório, ele entra na primeira rede ao alcance de uma lista de prioridade que você escolhe entre suas redes salvas, como o hotspot do seu celular. Escolher redes pelo nome exige acesso à localização, porque o macOS só mostra nomes de Wi-Fi para apps com esse acesso; sua localização nunca é usada. Se nenhuma funcionar, ele reinicia o Wi-Fi para o macOS voltar sozinho a uma rede salva.
- **Enquanto você estava fora.** Ao voltar para o Mac, o notch conta o que aconteceu: quanto tempo o Melatonin o manteve acordado, quais agentes trabalharam e por quanto tempo, de quantas quedas de Wi-Fi ele se recuperou e quanta bateria foi usada.
- **Segurança em primeiro lugar.**
  - Na bateria, desativa quando a carga chega ao limite que você escolher (20% por padrão).
  - Desativa se o seu Mac esquentar. Notebook ligado dentro de uma mochila fechada é o jeito certo de cozinhar a bateria.
  - Se o Melatonin for encerrado, falhar ou for fechado à força, a ferramenta auxiliar restaura o repouso normal na hora. Depois de uma reinicialização, ela também deixa tudo em ordem.
- **Nativo e leve.** SwiftUI e AppKit, sem Electron, cerca de 0% de CPU quando ocioso. Binário universal para Apple silicon e Intel.
- **Fala a sua língua.** English, 한국어, 简体中文, 日本語, Español, Français, Deutsch, Português (Brasil), Русский, العربية, हिन्दी e Bahasa Indonesia. Por padrão, segue o idioma do macOS; para escolher outro, vá em **⋯ › Idioma**.

<p align="center">
  <img src="docs/images/menu-on-light.png" width="300" alt="Menu, acordado">
  <img src="docs/images/menu-off-dark.png" width="300" alt="Menu, repouso permitido">
</p>

<p align="center">
  <img src="docs/images/notch-compact.png" width="640" alt="Pílula compacta no notch com contagem regressiva">
</p>

<p align="center">
  <img src="docs/images/notch-recap.png" width="640" alt="Resumo de enquanto você estava fora no notch">
</p>

<p align="center">
  <img src="docs/images/connection-light.png" width="420" alt="Ajustes de “Manter conexão”">
</p>

## Instalação

Requer macOS 14 Sonoma ou posterior.

**Download:** baixe o [Melatonin.dmg](https://github.com/jugol/Melatonin/releases/latest/download/Melatonin.dmg) da [versão mais recente](https://github.com/jugol/Melatonin/releases/latest) e arraste o app para a pasta Aplicativos.

**Homebrew:**

```bash
brew install --cask jugol/tap/melatonin
```

As versões publicadas são assinadas com um Developer ID e notarizadas pela Apple, então abrem como qualquer outro app.

O Melatonin se atualiza sozinho. Quando sai uma versão nova, aparece um pequeno selo no topo do menu; você também pode escolher **⋯ › Verificar Atualizações…**.

Na primeira vez que você ativar o Melatonin, o macOS vai pedir sua senha uma única vez para instalar a ferramenta auxiliar.

**A partir do código-fonte:** você precisa das Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/jugol/Melatonin.git
cd Melatonin
make run
```

## Como funciona

```
Melatonin.app  ──XPC──▶  io.github.jugol.melatonin.helper (root, launchd)
  UI, timers,              pmset -a disablesleep 1 / 0
  safety checks,           …and back to 0 when the app disconnects
  connection watch         networksetup -setairportpower (Wi-Fi off and on)
```

- **A ferramenta auxiliar expõe o mínimo.** A interface inteira se resume a `setSleepDisabled(Bool)` e mais duas chamadas de Wi-Fi: reiniciar o Wi-Fi e conectar a uma rede já salva no Mac. Não tem acesso ao shell nem executa comandos arbitrários. Confira em [`Sources/MelatoninHelper/main.swift`](Sources/MelatoninHelper/main.swift).
- **Só conversa com o Melatonin.** As conexões XPC precisam atender a um requisito de assinatura de código vinculado ao identificador de pacote do app.
- **É à prova de falhas.** O repouso só fica desativado enquanto um app conectado pedir. Se a conexão cair, o repouso volta. Um arquivo marcador cobre reinícios da ferramenta auxiliar e do sistema.
- **A instalação e a desinstalação são scripts de shell simples** que você pode ler: [`Support/install-helper.sh`](Support/install-helper.sh) e [`Support/uninstall-helper.sh`](Support/uninstall-helper.sh).

## Desinstalar

Escolha **⋯ › Desinstalar ferramenta auxiliar…** no menu e depois apague o app. Se preferir remover a ferramenta auxiliar manualmente:

```bash
sudo bash Support/uninstall-helper.sh
```

## Desenvolvimento

```bash
make app        # build build/Melatonin.app (signed with the best identity on this Mac)
make run        # build and launch
make package    # universal build, DMG and zip in dist/
make icon       # regenerate the app icon from Scripts/make-icon.swift
swift build && .build/debug/Melatonin --snapshot /tmp/shots   # render every UI state to PNGs
swift build && .build/debug/Melatonin --agents                 # watch agent detection live
```

Depois de adicionar ou editar uma tradução, rode `python3 Scripts/check-localizations.py` para encontrar textos faltando ou marcadores que não batem.

Os builds são assinados com o Developer ID deste Mac, se houver; senão, com uma identidade local criada por `Scripts/make-signing-identity.sh` (mantém o acesso à localização entre builds); senão, ad hoc. `make package` também faz a notarização quando existe um perfil de chaves do notarytool chamado `melatonin`. Para assinar com seu próprio Developer ID, defina `SIGN_IDENTITY`:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" make app
```

## Próximos passos

- [x] Versões assinadas e notarizadas e um cask do Homebrew
- [x] Manter conexão: entrar nas suas redes salvas na ordem que você escolher
- [x] Resumo "Enquanto você estava fora" quando você volta
- [x] Atualizações automáticas com Sparkle
- [x] Lê os registros de sessão do Claude Code e do Codex para saber quando cada turno começa e termina

## Licença

[MIT](LICENSE)
