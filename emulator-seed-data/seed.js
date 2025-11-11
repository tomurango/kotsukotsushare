const admin = require('firebase-admin');

// エミュレータに接続
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

admin.initializeApp({
  projectId: 'chokushii-1ecc5',
});

const db = admin.firestore();
const auth = admin.auth();

async function seedData() {
  try {
    console.log('Starting data seeding...');

    // テストユーザーを作成
    const testUsers = [
      { uid: 'test-user-1', email: 'test1@example.com', displayName: 'テストユーザー1' },
      { uid: 'test-user-2', email: 'test2@example.com', displayName: 'テストユーザー2' },
      { uid: 'test-user-3', email: 'test3@example.com', displayName: 'テストユーザー3' },
    ];

    console.log('Creating test users...');
    for (const user of testUsers) {
      try {
        await auth.createUser({
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          password: 'password123',
        });
        console.log(`✓ Created auth user: ${user.email}`);
      } catch (error) {
        if (error.code === 'auth/uid-already-exists') {
          console.log(`- Auth user already exists: ${user.email}`);
        } else {
          console.error(`✗ Failed to create auth user ${user.email}:`, error.message);
        }
      }

      // Firestoreにユーザードキュメントを作成
      await db.collection('users').doc(user.uid).set({
        tutorialCompleted: true,
      });
      console.log(`✓ Created Firestore user document: ${user.uid}`);
    }

    // テスト質問を作成
    console.log('\nCreating test questions...');
    const questions = [
      {
        id: 'question-1',
        text: '最近、自分に自信が持てなくて悩んでいます。同じような経験をした方、どうやって乗り越えましたか？',
        userId: 'test-user-1',
        userName: 'テストユーザー1',
        createdBy: 'test-user-1',
        createdAt: admin.firestore.Timestamp.now(),
        isFavorite: false,
        random: Math.random(),
      },
      {
        id: 'question-2',
        text: '仕事とプライベートのバランスが取れず、いつも疲れています。みなさんはどうやって両立していますか？',
        userId: 'test-user-2',
        userName: 'テストユーザー2',
        createdBy: 'test-user-2',
        createdAt: admin.firestore.Timestamp.now(),
        isFavorite: false,
        random: Math.random(),
      },
      {
        id: 'question-3',
        text: '新しいことを始めたいけど、失敗するのが怖くて一歩踏み出せません。どうすれば勇気が出るでしょうか？',
        userId: 'test-user-3',
        userName: 'テストユーザー3',
        createdBy: 'test-user-3',
        createdAt: admin.firestore.Timestamp.now(),
        isFavorite: false,
        random: Math.random(),
      },
    ];

    for (const question of questions) {
      await db.collection('questions').doc(question.id).set(question);
      console.log(`✓ Created question: ${question.text}`);
    }

    // テスト回答を作成
    console.log('\nCreating test answers...');
    const answers = [
      {
        id: 'answer-1',
        questionId: 'question-1',
        text: '私も同じ経験があります。小さな成功体験を積み重ねることで、少しずつ自信を取り戻せました。できることから始めてみてください！',
        userId: 'test-user-2',
        userName: 'テストユーザー2',
        createdAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'answer-2',
        questionId: 'question-2',
        text: '完璧を目指さないことが大切だと気づきました。仕事は8割の力で、残りの2割を自分の時間に使うようにしています。',
        userId: 'test-user-3',
        userName: 'テストユーザー3',
        createdAt: admin.firestore.Timestamp.now(),
      },
      {
        id: 'answer-3',
        questionId: 'question-3',
        text: '失敗は成長のチャンスです。最初から完璧にできる人なんていません。まずは小さく始めてみることをおすすめします！',
        userId: 'test-user-1',
        userName: 'テストユーザー1',
        createdAt: admin.firestore.Timestamp.now(),
      },
    ];

    for (const answer of answers) {
      await db
        .collection('questions')
        .doc(answer.questionId)
        .collection('answers')
        .doc(answer.id)
        .set(answer);
      console.log(`✓ Created answer for question: ${answer.questionId}`);
    }

    console.log('\n✅ Data seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  }
}

seedData();
