/**
 * firestore.rules.test.js
 * Firebase Security Rules テスト
 * Jest + Firebase Emulator で全分岐をカバー（C1カバレッジ）
 *
 * 【テスト対象ルール】
 *   /users/{uid}
 *     - get:   本人 or 管理者
 *     - list:  管理者のみ
 *     - write: 本人 or 管理者
 *   /users/{uid}/cards/{cardId}
 *     - read, write: 本人のみ
 *   /admin_access_logs/{logId}
 *     - read, write: 管理者のみ
 *
 * 【前提】
 *   firebase emulators:start --only firestore を起動してから実行
 */

const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require("@firebase/rules-unit-testing");
const { readFileSync } = require("fs");
const { resolve } = require("path");

// ── 定数 ─────────────────────────────────────────────────────
const PROJECT_ID  = "meishimanager";
const RULES_PATH  = resolve(__dirname, "../../firestore.rules");

// ── テストユーザー ─────────────────────────────────────────────
const USER_A_UID   = "user-a";
const USER_B_UID   = "user-b";
const ADMIN_UID    = "admin-user";

// ── 環境セットアップ ──────────────────────────────────────────
let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });

  // 管理者ドキュメントをEmulatorに事前作成（isAdmin()関数が参照する）
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.collection("users").doc(ADMIN_UID).set({
      role: "admin",
      name: "管理者",
      email: "admin@example.com",
    });
    await db.collection("users").doc(USER_A_UID).set({
      role: "user",
      name: "ユーザーA",
      email: "usera@example.com",
    });
    await db.collection("users").doc(USER_B_UID).set({
      role: "user",
      name: "ユーザーB",
      email: "userb@example.com",
    });
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  // 各テスト前にデータを再作成
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.collection("users").doc(ADMIN_UID).set({
      role: "admin", name: "管理者", email: "admin@example.com",
    });
    await db.collection("users").doc(USER_A_UID).set({
      role: "user", name: "ユーザーA", email: "usera@example.com",
    });
    await db.collection("users").doc(USER_B_UID).set({
      role: "user", name: "ユーザーB", email: "userb@example.com",
    });
    // 名刺データ
    await db
      .collection("users").doc(USER_A_UID)
      .collection("cards").doc("card-1")
      .set({ name: "テスト名刺", company: "テスト会社" });
    // アクセスログ
    await db.collection("admin_access_logs").doc("log-1").set({
      action: "test", adminUid: ADMIN_UID,
    });
  });
});

// ================================================================
// /users/{uid} - get
// ================================================================
describe("/users/{uid} - get", () => {
  test("✅ 本人は自分のドキュメントを取得できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(db.collection("users").doc(USER_A_UID).get());
  });

  test("✅ 管理者は他のユーザーのドキュメントを取得できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(db.collection("users").doc(USER_A_UID).get());
  });

  test("❌ 未認証ユーザーは取得できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection("users").doc(USER_A_UID).get());
  });

  test("❌ 他のユーザーのドキュメントは取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_B_UID).firestore();
    await assertFails(db.collection("users").doc(USER_A_UID).get());
  });
});

// ================================================================
// /users/{uid} - list
// ================================================================
describe("/users/{uid} - list", () => {
  test("✅ 管理者はユーザー一覧を取得できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(db.collection("users").get());
  });

  test("❌ 一般ユーザーはユーザー一覧を取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(db.collection("users").get());
  });

  test("❌ 未認証ユーザーはユーザー一覧を取得できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.collection("users").get());
  });
});

// ================================================================
// /users/{uid} - write
// ================================================================
describe("/users/{uid} - write", () => {
  test("✅ 本人は自分のドキュメントを更新できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).update({ name: "更新済み" })
    );
  });

  test("✅ 管理者は他のユーザーのドキュメントを更新できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).update({ name: "管理者が更新" })
    );
  });

  test("❌ 未認証ユーザーは書き込みできない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).update({ name: "不正" })
    );
  });

  test("❌ 他のユーザーのドキュメントは更新できない", async () => {
    const db = testEnv.authenticatedContext(USER_B_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).update({ name: "不正" })
    );
  });
});

// ================================================================
// /users/{uid}/cards/{cardId} - read
// ================================================================
describe("/users/{uid}/cards/{cardId} - read", () => {
  test("✅ 本人は自分の名刺を取得できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1").get()
    );
  });

  test("❌ 他のユーザーの名刺は取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_B_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1").get()
    );
  });

  test("❌ 管理者でも他のユーザーの名刺は取得できない", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1").get()
    );
  });

  test("❌ 未認証ユーザーは名刺を取得できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1").get()
    );
  });
});

// ================================================================
// /users/{uid}/cards/{cardId} - write
// ================================================================
describe("/users/{uid}/cards/{cardId} - write", () => {
  test("✅ 本人は自分の名刺を作成できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-new")
        .set({ name: "新しい名刺", company: "新会社" })
    );
  });

  test("✅ 本人は自分の名刺を更新できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1")
        .update({ name: "更新名刺" })
    );
  });

  test("✅ 本人は自分の名刺を削除できる", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1").delete()
    );
  });

  test("❌ 他のユーザーの名刺は作成できない", async () => {
    const db = testEnv.authenticatedContext(USER_B_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-new")
        .set({ name: "不正名刺" })
    );
  });

  test("❌ 管理者でも他のユーザーの名刺は書き込みできない", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-1")
        .update({ name: "不正更新" })
    );
  });

  test("❌ 未認証ユーザーは名刺を書き込みできない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-new")
        .set({ name: "不正" })
    );
  });
});

// ================================================================
// /admin_access_logs/{logId} - read
// ================================================================
describe("/admin_access_logs/{logId} - read", () => {
  test("✅ 管理者はアクセスログを取得できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(
      db.collection("admin_access_logs").doc("log-1").get()
    );
  });

  test("✅ 管理者はアクセスログ一覧を取得できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(db.collection("admin_access_logs").get());
  });

  test("❌ 一般ユーザーはアクセスログを取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-1").get()
    );
  });

  test("❌ 未認証ユーザーはアクセスログを取得できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-1").get()
    );
  });
});

// ================================================================
// /admin_access_logs/{logId} - write
// ================================================================
describe("/admin_access_logs/{logId} - write", () => {
  test("✅ 管理者はアクセスログを作成できる", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(
      db.collection("admin_access_logs").doc("log-new").set({
        action: "create", adminUid: ADMIN_UID,
      })
    );
  });

  test("❌ 一般ユーザーはアクセスログを作成できない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-new").set({
        action: "不正", adminUid: USER_A_UID,
      })
    );
  });

  test("❌ 未認証ユーザーはアクセスログを作成できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-new").set({
        action: "不正",
      })
    );
  });
});

// ================================================================
// 異常系: フィールド改ざん
// ================================================================
describe("フィールド改ざん - role昇格の試み", () => {
  test("❌ 一般ユーザーは自分のroleをadminに書き換えられない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).update({ role: "admin" })
    );
  });

  test("❌ 一般ユーザーは他ユーザーのroleをadminに書き換えられない", async () => {
    const db = testEnv.authenticatedContext(USER_B_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_A_UID).update({ role: "admin" })
    );
  });
});

describe("フィールド改ざん - adminUid偽装", () => {
  test("❌ 一般ユーザーはadminUidを偽装してアクセスログを書き込めない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-fake").set({
        action: "fake_action",
        adminUid: ADMIN_UID, // 管理者のuidを偽装
      })
    );
  });

  test("❌ 一般ユーザーは自分のuidでもアクセスログを書き込めない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-fake").set({
        action: "fake_action",
        adminUid: USER_A_UID,
      })
    );
  });
});

describe("フィールド改ざん - 他ユーザーの名刺パスに自分のuidで書き込む", () => {
  test("❌ userAはuserBのパスに自分のuidを使っても名刺を作成できない", async () => {
    // /users/USER_B_UID/cards/ に userA が書き込もうとする
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_B_UID).collection("cards").doc("card-fake")
        .set({ name: "不正名刺", ownerUid: USER_A_UID })
    );
  });

  test("❌ userAはuserBの名刺を更新できない", async () => {
    // 事前にuserBの名刺を作成
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection("users").doc(USER_B_UID)
        .collection("cards").doc("card-b1")
        .set({ name: "ユーザーBの名刺" });
    });
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("users").doc(USER_B_UID).collection("cards").doc("card-b1")
        .update({ name: "改ざん" })
    );
  });
});

// ================================================================
// 異常系: 存在しないドキュメント
// ================================================================
describe("存在しないドキュメントへのアクセス", () => {
  test("❌ 未認証ユーザーは存在しないユーザードキュメントを取得できない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("users").doc("non-existent-uid").get()
    );
  });

  test("❌ 一般ユーザーは存在しない他ユーザーのドキュメントを取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("users").doc("non-existent-uid").get()
    );
  });

  test("❌ 一般ユーザーは存在しないログを取得できない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("non-existent-log").get()
    );
  });

  test("✅ 管理者は存在しないログドキュメントも取得操作できる（空でも許可）", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertSucceeds(
      db.collection("admin_access_logs").doc("non-existent-log").get()
    );
  });
});

// ================================================================
// 異常系: 境界値
// ================================================================
describe("境界値 - 空フィールド・長い文字列", () => {
  test("✅ 本人は空文字のnameで自分のドキュメントを更新できる（ルール上は許可）", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).update({ name: "" })
    );
  });

  test("✅ 本人は非常に長い文字列で名刺を作成できる（ルール上は許可）", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    const longString = "あ".repeat(1000);
    await assertSucceeds(
      db.collection("users").doc(USER_A_UID).collection("cards").doc("card-long")
        .set({ name: longString, company: longString })
    );
  });

  test("❌ 未認証ユーザーは空フィールドでもアクセスログを書き込めない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-empty").set({
        action: "",
        adminUid: "",
      })
    );
  });

  test("❌ 一般ユーザーは空フィールドでもアクセスログを書き込めない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("admin_access_logs").doc("log-empty").set({
        action: "",
        adminUid: "",
      })
    );
  });
});

// ================================================================
// 異常系: 不正なコレクションへのアクセス
// ================================================================
describe("不正なコレクション・パスへのアクセス", () => {
  test("❌ 未認証ユーザーは任意のコレクションに書き込めない", async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      db.collection("unknown_collection").doc("doc-1").set({ data: "不正" })
    );
  });

  test("❌ 一般ユーザーは定義外のコレクションに書き込めない", async () => {
    const db = testEnv.authenticatedContext(USER_A_UID).firestore();
    await assertFails(
      db.collection("unknown_collection").doc("doc-1").set({ data: "不正" })
    );
  });

  test("❌ 管理者も定義外のコレクションには書き込めない", async () => {
    const db = testEnv.authenticatedContext(ADMIN_UID).firestore();
    await assertFails(
      db.collection("unknown_collection").doc("doc-1").set({ data: "不正" })
    );
  });
});
