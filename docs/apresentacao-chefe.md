# Apelmat Empregos - Resumo para apresentacao

## Ideia

Aplicativo mobile com catalogo controlado pela Apelmat:

- profissionais cadastram curriculo e ate 3 areas de trabalho;
- contratantes veem somente profissionais aprovados;
- contatos ficam ocultos ate a Apelmat liberar manualmente.

## O que esta construido

- Flutter para Android e iOS com logo e icone oficiais.
- Backend Django REST Framework com MySQL em producao.
- Cadastro publico somente para profissional; contratante criado pelo admin.
- Catalogo de profissionais aprovados com busca textual.
- Curriculo PDF protegido e oculto antes da liberacao.
- Solicitacao de contato com status manual pela Apelmat.
- Contatos por WhatsApp e e-mail fora da plataforma.
- Avisos internos, denuncias, exclusao de conta e painel administrativo.
- HTTPS automatico, backups e implantacao Docker para a VPS Locaweb.
- APK para teste e AAB assinado para a Google Play.

## Como demonstrar

1. Inicie o backend e acesse `http://localhost:8000/admin/`.
2. Entre no app com `profissional@apelmat.com` e mostre curriculo, areas e avisos.
3. Entre com `contratante@apelmat.com` e abra o catalogo.
4. Solicite contato de um profissional.
5. Entre com `admin@apelmat.com`, abra solicitacoes e libere ou recuse.
6. Volte no contratante e mostre WhatsApp, e-mail e PDF liberados.

## Limites definidos

A Apelmat aproxima as partes. Chat, pagamento, contrato e selecao acontecem
fora da plataforma. Notificacao do Android com o app fechado fica para uma
integracao futura com Firebase; os avisos internos ja funcionam no servidor.
