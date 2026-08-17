# Publicacao na Google Play

O identificador Android do novo aplicativo e:

```text
br.com.apelmat.apelmat_empregos
```

O APK incluido no pacote esta em modo release, conectado ao dominio oficial e
pode ser instalado para teste. Como a chave definitiva da nova conta ainda nao
foi criada, ele usa a assinatura de desenvolvimento e nao deve ser enviado para
a Google Play.

Antes da primeira publicacao:

1. Crie e guarde uma chave de upload `.jks`.
2. Copie `app/android/key.properties.example` para
   `app/android/key.properties` e preencha os dados.
3. Coloque a chave em `app/android/app/upload-keystore.jks`.
4. Execute `deploy/build-aab.ps1` com a URL oficial da API.
5. Guarde a chave e suas senhas em local seguro e com backup.

Comando recomendado:

```powershell
powershell -ExecutionPolicy Bypass -File .\deploy\build-aab.ps1 -ApiBaseUrl "https://empregos.apelmat.com.br/api"
```

O arquivo para subir na Google Play fica em:

```text
app/build/app/outputs/bundle/release/app-release.aab
```

O projeto Gradle detecta `key.properties` automaticamente. Sem esse arquivo,
ele usa assinatura de desenvolvimento apenas para permitir testes instalaveis.
