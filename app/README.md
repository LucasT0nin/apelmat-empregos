# Aplicativo Apelmat Empregos

Aplicativo Flutter oficial para Android e iOS. O mural permite publicar e
pesquisar dois tipos de anuncio:

- `Quero trabalhar`: oferta publicada por profissional, com valor opcional;
- `Quero contratar`: pedido publicado por contratante.

Use `flutter run` para desenvolvimento. O endereco da API pode ser definido com:

```powershell
flutter run --dart-define=API_BASE_URL=http://SEU-IP:8000/api
```

Em producao, os artefatos sao compilados para
`https://empregos.apelmat.com.br/api`.
