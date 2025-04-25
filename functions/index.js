const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// メール送信設定
const transporter = nodemailer.createTransport({
  service: "gmail", // Gmailを使用
  auth: {
    user: "sanyuanyouhui17@gmail.com", // 送信元メールアドレス
    pass: "913enter", // アプリパスワード
  },
});

// メール送信関数
exports.sendEmail = functions.https.onCall(async (data, context) => {
  const {to, subject, message} = data;

  // データ検証
  if (!to || !subject || !message) {
    console.error("Missing required fields: to, subject, or message");
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields: to, subject, or message",
    );
  }

  const mailOptions = {
    from: "sanyuanyouhui17@gmail.com",
    to,
    subject,
    text: message,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Email sent to ${to} with subject: ${subject}`);
    return {success: true};
  } catch (error) {
    console.error("Error sending email:", error.message);
    throw new functions.https.HttpsError(
        "internal",
        `Unable to send email: ${error.message}`,
    );
  }
});
