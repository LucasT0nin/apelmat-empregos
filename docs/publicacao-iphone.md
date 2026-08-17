# Publicacao no iPhone

Este projeto ja esta configurado para iOS com:

- Nome do app: Apelmat Empregos
- Bundle ID iOS: `br.com.apelmat.apelmatempregos`
- Icone do app: `app/assets/images/apelmat_app_icon.png`
- Rede local liberada no `Info.plist` para testes internos

## Ponto importante

Nao da para gerar um app de iPhone instalavel direto pelo Windows. Para iPhone,
o arquivo `.ipa` precisa ser compilado e assinado em macOS com Xcode ou por um
servico de build iOS usando uma conta Apple Developer.

## Para testar em um iPhone pela rede local

No Mac com Flutter e Xcode instalados:

```bash
cd app
flutter pub get
flutter run -d ios --dart-define=API_BASE_URL=http://192.168.0.67:8000/api
```

O servidor local precisa estar ligado no Windows:

```powershell
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
```

O iPhone e o Windows precisam estar na mesma rede.

## Para gerar IPA de producao

No Mac:

```bash
cd app
flutter build ipa --release --dart-define=API_BASE_URL=https://empregos.apelmat.com.br/api
```

Depois suba o `.ipa` pelo Xcode Organizer ou Transporter para TestFlight/App
Store Connect.

## O que precisa da Apple

- Conta Apple Developer ativa.
- App criado no App Store Connect.
- Bundle ID igual a `br.com.apelmat.apelmatempregos`.
- Signing Team configurado no Xcode.
- Certificado e provisioning profile automaticos pelo Xcode ou configurados
  manualmente no build cloud.
