# Como o Apelmat Empregos funciona

## Ideia central

O sistema nao e mais um mural aberto. Ele e um catalogo controlado pela
Apelmat. Para a empresa, a experiencia parece simples: pesquisar, escolher e
solicitar contato. Por tras, a Apelmat aprova manualmente quem recebe cada
contato.

## Contas e acesso

Existem tres tipos de acesso: profissional, contratante e admin Apelmat. O
cadastro publico cria somente conta profissional. Contratantes sao cadastrados
pela Apelmat no painel admin. A sessao usa tokens JWT guardados no armazenamento
seguro do celular. Quem perde a senha fala com a Apelmat pelo WhatsApp de
suporte.

## Profissional

1. Preenche o curriculo base com resumo, experiencia, cidade e UF.
2. Pode anexar PDF, mas o PDF e opcional.
3. Escolhe ate 3 areas de trabalho:
   operador, motorista de caminhao, encarregado ou engenheiro.
4. Responde perguntas especificas da funcao.
5. O perfil fica `Em analise`.
6. A Apelmat aprova no admin e publica no catalogo.
7. O profissional acompanha avisos e status, mas nao ve vagas de empresas.

## Empresa

1. Entra no catalogo de profissionais publicados.
2. Pesquisa por nome, cidade, resumo ou experiencia.
3. Ve dados profissionais, areas, resumo e selo Apelmat.
4. Nao ve WhatsApp, e-mail nem PDF inicialmente.
5. Clica em `Solicitar contato`.
6. A solicitação aparece no painel administrativo da Apelmat.
7. Quando a Apelmat libera, a empresa passa a ver WhatsApp, e-mail e curriculo.

## Admin Apelmat

No Django Admin, a Apelmat pode:

- aprovar ou pausar curriculos;
- publicar ou recusar areas profissionais;
- ver solicitacoes de contato;
- liberar ou recusar contatos;
- abrir WhatsApp do profissional ou da empresa;
- acompanhar avisos e historico;
- administrar usuarios, empresas e denuncias.

## Protecao contra empresas pegarem tudo

O sistema nao libera contatos automaticamente. Cada solicitacao fica pendente
ate o admin decidir. Assim, no começo a Apelmat controla manualmente o volume e
evita que uma empresa grande pegue todos os profissionais antes dos associados
menores.

## Avisos

Os avisos ficam no banco e aparecem dentro do app. O aplicativo busca novos
avisos periodicamente enquanto esta aberto. Sem Firebase, o Android ainda nao
mostra push quando o app esta totalmente fechado.

## Servidor e banco

O app oficial acessa `https://empregos.apelmat.com.br/api`. Na VPS, Caddy cuida
do HTTPS, Gunicorn executa o Django e o MySQL 8.4 guarda os dados em volume
persistente. Curriculos ficam em volume separado.
