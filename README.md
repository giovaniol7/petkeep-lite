# 🐾 PetKeeper Lite

Aplicativo desenvolvido em Flutter para gerenciamento colaborativo de tarefas, vacinas e cuidados de pets entre membros de uma mesma família.  
Integra autenticação, notificações em tempo real e sincronização via Firebase.

---

## 📱 Funcionalidades

### 👨‍👩‍👧‍👦 Famílias
- Criação e ingresso em grupos familiares por **código único** (`familyCode`);
- Associação automática entre usuários e pets da mesma família;
- Isolamento total de dados entre famílias via regras do Firestore.

### 🐶 Pets
- Cadastro de pets com:
    - nome, espécie, peso, data de nascimento e foto;
- Upload da foto para **Firebase Storage** (`pet_photos/{petId}.jpg`);
- Exibição da imagem circular e dados principais no topo da tela;
- Listagem filtrada por família atual.

### 📋 Tarefas
- Criação, listagem e marcação de tarefas associadas ao pet;
- Atualização em tempo real via **StreamProvider (Riverpod)**;
- Tipos de tarefa: Vacina, Banho/Tosa e Outros;
- Interface intuitiva com `CheckboxListTile`.

### 🔔 Notificações
- Integração com **Firebase Cloud Messaging (FCM)**;
- Função Cloud Function `notifyFamily` que:
    - Busca todos os tokens da família;
    - Envia notificação multicast;
- Notificação local exibida no dispositivo via `flutter_local_notifications`.

### 🔐 Autenticação
- Login com **Google** e **E-mail/Senha** (Firebase Auth);
- Registro automático no Firestore em `users/{uid}`;
- Armazenamento do token local via `SharedPreferences`;
- Logout remove token e FCM associado.

### 🛡️ Segurança e App Check
- **Firebase App Check** configurado com modo `debug`;
- Regras de Firestore e Storage isolando famílias;
- Comunicação segura entre app e funções via App Check Token.

---

## 🧠 Arquitetura

![image1.png](assets/print/image1.png)
![image2.png](assets/print/image2.png)
![image3.png](assets/print/image3.png)
![image4.png](assets/print/image4.png)
![image5.png](assets/print/image5.png)
![image6.png](assets/print/image6.png)
![image7.png](assets/print/image7.png)
![image8.png](assets/print/image8.png)

## ⚙️ Configuração e Execução

### 1️⃣ Pré-requisitos
- Flutter 3.24+
- Firebase CLI (`npm install -g firebase-tools`)
- Conta Firebase com Auth, Firestore, Storage e Messaging habilitados

### 2️⃣ Configuração Firebase
1. Crie um projeto no [Firebase Console](https://console.firebase.google.com)
2. Ative:
  - Authentication (Google e E-mail/Senha)
  - Firestore Database
  - Storage
  - Cloud Functions
  - Cloud Messaging
3. Baixe e adicione:
  - `google-services.json` → `android/app/`
  - `GoogleService-Info.plist` → `ios/Runner/`
4. Configure o App Check em modo `debug`:
   ```dart
   await FirebaseAppCheck.instance.activate(
     androidProvider: AndroidProvider.debug,
     appleProvider: AppleProvider.debug,
   );

3️⃣ Rodar localmente
flutter pub get
firebase emulators:start
flutter run

☁️ Estrutura do Firestore
users/{uid}
displayName, email, familyCode, fcmTokens[]

families/{familyCode}
createdAt, ownerUid

pets/{petId}
familyCode, name, species, birthDate, weightKg, photoUrl, createdAt

pet_tasks/{taskId}
petId, type, title, dueDate, notes, createdBy, createdAt, done

🔒 Regras de Segurança (Firestore + Storage)
rules_version = '2';
service cloud.firestore {
match /databases/{db}/documents {
function userFamily() {
return get(/databases/$(db)/documents/users/$(request.auth.uid)).data.familyCode;
}

    match /users/{uid} {
      allow read, write: if request.auth != null && uid == request.auth.uid;
    }

    match /families/{familyCode} {
      allow read, write: if request.auth != null && familyCode == userFamily();
    }

    match /pets/{petId} {
      allow read, write: if request.auth != null
        && request.resource.data.familyCode == userFamily();
    }

    match /pet_tasks/{taskId} {
      allow read: if request.auth != null
        && exists(/databases/$(database)/documents/pets/$(resource.data.petId))
        && get(/databases/$(database)/documents/pets/$(resource.data.petId)).data.familyCode == userFamily();
      allow write: if request.auth != null
        && exists(/databases/$(database)/documents/pets/$(request.resource.data.petId))
        && get(/databases/$(database)/documents/pets/$(request.resource.data.petId)).data.familyCode == userFamily();
    }
}
}

service firebase.storage {
match /b/{bucket}/o {
match /pet_photos/{file} {
allow read, write: if request.auth != null;
}
}
}

💬 Uso do Cursor (obrigatório no desafio)

Durante o desenvolvimento, utilizei o Cursor AI para gerar e refatorar stubs de código.
Abaixo, alguns prompts usados e como o código foi ajustado manualmente:

Prompt utilizado	Ajuste manual
“Crie provider Riverpod para listar pets de uma família no Firestore.”	Substituí o uso de FutureProvider por StreamProvider para garantir atualizações em tempo real e evitar polling manual.
“Implemente função Cloud Function notifyFamily que envia push para todos tokens do familyCode.”	Ajustei o envio multicast do FCM para tratar tokens inválidos e removê-los do Firestore automaticamente.
“Crie modelo de regra de segurança para validar pets e tarefas por familyCode.”	Reescrevi a função userFamily() e simplifiquei getFamilyPetIds() conforme restrição do desafio (sem lookups aninhados).
“Monte tela de Detalhe do Pet com lista de tarefas usando CheckboxListTile.”	Refatorei para usar Consumer e AsyncValue do Riverpod, mantendo UI responsiva e sem rebuilds desnecessários.

Esses ajustes garantiram melhor performance, segurança e organização do projeto.

🎥 Demonstração em Vídeo

📹 Link: https://youtube.com/shorts/LWt0xPBflm4

O vídeo mostra:

Login (Google e E-mail/Senha)
Criação e entrada em família (familyCode)
Cadastro de pet + upload de foto
Criação e atualização de tarefas
Envio e recebimento de notificações entre dispositivos

👨‍💻 Autor
Giovani Oliveira Lazzarini