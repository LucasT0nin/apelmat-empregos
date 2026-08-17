# Regras oficiais do Apelmat Empregos

## Produto

- Nome: Apelmat Empregos.
- Dominio: `empregos.apelmat.com.br`.
- O produto e um catalogo controlado de profissionais, nao um mural aberto.
- A Apelmat aproxima as partes e nao intermedeia negociacao, pagamento ou
  contrato.

## Profissional

- Pode cadastrar curriculo base.
- Pode anexar PDF opcional.
- Pode escolher ate 3 areas profissionais:
  operador, motorista de caminhao, encarregado e engenheiro.
- Cada area possui perguntas especificas para analise da Apelmat.
- Nao ve vagas de empresas.
- Recebe avisos sobre analise, publicacao e contato encaminhado.

## Empresa

- Pode consultar o catalogo de profissionais publicados.
- Pode pesquisar e filtrar pelo conteudo do perfil.
- Nao recebe WhatsApp, e-mail ou PDF antes da liberacao.
- Pode clicar em `Solicitar contato`.
- Acompanha status das solicitacoes.

## Apelmat

- Aprova curriculos e aplica selo `verificado pela Apelmat`.
- Publica, pausa ou recusa areas profissionais.
- Recebe solicitacoes de contato no Django Admin.
- Libera ou recusa cada contato manualmente.
- Pode abrir WhatsApp do profissional ou da empresa pelo painel.
- Administra contas, denuncias e dados sensiveis.

## Contato

- Profissionais e empresas informam WhatsApp e e-mail.
- O aplicativo abre WhatsApp e e-mail fora da plataforma.
- Recuperacao de acesso e feita pelo WhatsApp `+55 11 93339-8386`.
- Suporte oficial: `apelmat.ti@apelmat.com.br`.

## Privacidade

- Dados de contato e PDF ficam ocultos ate a aprovacao da Apelmat.
- O backend valida as permissoes mesmo se alguem tentar acessar a API direto.
- Excluir uma conta remove registros associados e arquivo de curriculo.
