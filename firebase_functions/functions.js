const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

exports.generateCustomToken = functions.https.onRequest(async (req, res) => {
  try {
    // リクエストヘッダーからLINEアクセストークンを取得
    const accessToken = req.headers.authorization?.split("Bearer ")[1];
    if (!accessToken) {
      return res.status(400).send("アクセストークンが提供されていません。");
    }

    // LINEのユーザー情報を取得
    const userInfoResponse = await fetch("https://api.line.me/v2/profile", {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!userInfoResponse.ok) {
      return res.status(400).send("LINEユーザー情報の取得に失敗しました。");
    }

    const userInfo = await userInfoResponse.json();

    // Firebaseカスタムトークンを生成
    const customToken = await admin.auth().createCustomToken(userInfo.userId, {
      name: userInfo.displayName,
      picture: userInfo.pictureUrl,
    });

    return res.json({ customToken });
  } catch (error) {
    console.error("カスタムトークンの生成中にエラーが発生しました:", error);
    return res.status(500).send("カスタムトークンの生成に失敗しました。");
  }
});
