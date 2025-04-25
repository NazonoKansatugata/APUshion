const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

// メール送信設定
const transporter = nodemailer.createTransport({
  host: "smtp.gmail.com",
  port: 587,
  secure: false, // TLSを使用
  auth: {
    user: "your-email@gmail.com", // 送信元メールアドレス
    pass: "your-app-password", // アプリパスワード
  },
});

// メール送信関数
exports.sendEmail = functions.https.onCall(async (data, context) => {
  const {to, subject, message} = data;

  const mailOptions = {
    from: "your-email@gmail.com",
    to,
    subject,
    text: message,
  };

  try {
    await transporter.sendMail(mailOptions);
    return {success: true};
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", "Unable to send email");
  }
});
