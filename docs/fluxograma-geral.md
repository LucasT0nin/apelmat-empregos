# Fluxograma geral - Apelmat Empregos

```mermaid
flowchart TD
    A[App abre] --> B{Sessao salva?}
    B -->|Nao| C[Tela inicial]
    B -->|Sim| D[API /accounts/me/]
    C --> E[Entrar]
    C --> F[Criar conta profissional]
    C --> G[Termos e privacidade]
    E --> H[API /auth/token/]
    F --> I[API /accounts/register/]
    H --> D
    I --> H
    D --> J{Tipo de conta}

    J -->|Profissional| P1[Inicio profissional]
    J -->|Contratante| C1[Inicio contratante]
    J -->|Admin staff| A1[Painel admin]

    P1 --> P2[Meu curriculo]
    P1 --> P3[Minhas areas]
    P1 --> P4[Avisos]
    P1 --> P5[Perfil]
    P2 --> P6[Salvar dados e PDF opcional]
    P6 --> P7[Status volta para analise]
    P7 --> A2[Admin recebe aviso]
    P3 --> P8[Criar, editar ou remover ate 3 areas]
    P8 --> P9[Operador, motorista, encarregado, engenheiro ou outros]
    P9 --> A3[Admin analisa area]
    P4 --> P10[Ver aprovacao, recusa ou contato encaminhado]
    P5 --> P11[Sair ou excluir conta]

    C1 --> C2[Catalogo]
    C1 --> C3[Pedidos]
    C1 --> C4[Perfil]
    C2 --> C5[Pesquisar profissional publicado]
    C5 --> C6[Dados sensiveis ocultos]
    C6 --> C7[Solicitar contato]
    C7 --> A4[Admin recebe solicitacao]
    C3 --> C8[Acompanhar status]
    C8 -->|Aprovado| C9[Ver WhatsApp, e-mail e PDF]
    C8 -->|Pendente ou recusado| C10[Contato continua bloqueado]

    A1 --> A5[Curriculos]
    A1 --> A6[Areas profissionais]
    A1 --> A7[Inserir contratante]
    A1 --> A8[Solicitacoes de contato]
    A1 --> A9[Avisos]
    A5 --> A10[Publicar, pausar, revisar e baixar PDF]
    A6 --> A11[Publicar, recusar, revisar e chamar candidato]
    A7 --> A12[Criar conta de empresa]
    A8 --> A13[Liberar ou recusar contato]
    A13 --> C9
    A13 --> P10

    subgraph Backend
        B1[JWT login e refresh]
        B2[Permissoes por tipo de conta]
        B3[Catalogo controlado]
        B4[Notificacoes internas]
        B5[PDF protegido]
    end

    H --> B1
    D --> B2
    C2 --> B3
    A13 --> B4
    C9 --> B5
```

## Regras principais

- Cadastro publico cria somente conta profissional.
- Contratante e criado somente pelo admin.
- Profissional nao acessa catalogo de outros profissionais.
- Contratante ve catalogo, mas nao ve WhatsApp, e-mail nem PDF antes da liberacao.
- Admin controla publicacao de curriculo, publicacao de area e liberacao de contato.
- Cada profissional pode cadastrar no maximo 3 areas.
- PDF do curriculo so e baixado pelo proprio profissional, pelo admin ou por contratante aprovado.
