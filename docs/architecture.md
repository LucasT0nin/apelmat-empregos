# Arquitetura

## Visao geral

O projeto e um monolito modular: Flutter no celular, API REST Django no servidor
e banco relacional na VPS.

```text
Flutter -> API REST Django -> SQLite local / MySQL producao
                         -> armazenamento de curriculos PDF
                         -> Django Admin
```

## Modulos do backend

- `accounts`: usuarios, login, perfis de profissional/empresa e download seguro
  de curriculos.
- `marketplace`: areas profissionais, solicitacoes de contato, avisos internos e
  modelos antigos mantidos para compatibilidade/migracao.
- `moderation`: denuncias e bloqueios.
- `config`: configuracao da aplicacao e rotas globais.

## Papeis

A conta operacional pode ser:

- profissional;
- empresa/contratante;
- admin Apelmat.

O profissional cadastra curriculo e areas. A empresa consulta o catalogo e
solicita contato. A Apelmat aprova manualmente no admin. O cadastro publico
cria somente profissional; empresa e admin sao criados pela Apelmat.

## Modelos principais

- `ProfessionalProfile`: curriculo base, status de catalogo e selo Apelmat.
- `ProfessionalObjective`: ate 3 areas por profissional, com perguntas
  especificas.
- `ContactRequest`: empresa solicita contato de um profissional; admin libera ou
  recusa.
- `Notification`: avisos internos do app.

## Decisoes importantes

- UUIDs evitam expor contadores sequenciais.
- Dados de contato e PDF so aparecem apos aprovacao.
- Tokens JWT autenticam o aplicativo mobile.
- Django Admin atende a operacao interna da Apelmat.
- Arquivos nao ficam dentro do banco.
- O aplicativo nao acessa o banco diretamente.

## Evolucao planejada

Limites automaticos por empresa, Firebase push, relatorios avancados e filas em
segundo plano podem entrar depois. No lancamento, o controle de liberacao e
manual pelo admin, que e exatamente o desejado para proteger a distribuicao.
