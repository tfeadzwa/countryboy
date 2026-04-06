import nodemailer from 'nodemailer';
import logger from './logger';

const smtpUser = process.env.SMTP_USER || 'tfadzwa02@gmail.com';
const smtpPass = process.env.SMTP_PASS;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: smtpUser,
    pass: smtpPass,
  },
});

export const sendPasswordResetEmail = async (to: string, resetLink: string) => {
  if (!smtpPass) {
    logger.warn('SMTP_PASS is missing. Skipping password reset email send.');
    return;
  }

  await transporter.sendMail({
    from: `Countryboy Support <${smtpUser}>`,
    to,
    subject: 'Reset your Countryboy password',
    text: `A password reset was requested for your account.\n\nUse this link to reset your password:\n${resetLink}\n\n⚠ This link expires in 30 minutes. After that, you will need to request a new one.\n\nIf you did not request this, you can safely ignore this email.`,
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Reset your password</title>
</head>
<body style="margin:0;padding:0;background-color:#f3f4f6;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f3f4f6;padding:40px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;">

          <!-- Header -->
          <tr>
            <td align="center" style="padding-bottom:24px;">
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background:linear-gradient(135deg,#0f766e,#0891b2);border-radius:12px;padding:10px 14px;">
                    <span style="font-size:18px;font-weight:bold;color:#ffffff;letter-spacing:0.5px;">&#128652; CountryBoy</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Card -->
          <tr>
            <td style="background:#ffffff;border-radius:16px;box-shadow:0 4px 24px rgba(0,0,0,0.08);overflow:hidden;">

              <!-- Top accent bar -->
              <div style="height:4px;background:linear-gradient(90deg,#0f766e,#0891b2);"></div>

              <!-- Card body -->
              <table width="100%" cellpadding="0" cellspacing="0" style="padding:36px 40px;">
                <tr>
                  <td>
                    <!-- Icon -->
                    <div style="text-align:center;margin-bottom:24px;">
                      <div style="display:inline-block;background:#f0fdfa;border-radius:50%;padding:16px;">
                        <span style="font-size:32px;">&#128274;</span>
                      </div>
                    </div>

                    <!-- Title -->
                    <h1 style="margin:0 0 8px;font-size:22px;font-weight:700;color:#111827;text-align:center;">
                      Reset your password
                    </h1>
                    <p style="margin:0 0 28px;font-size:14px;color:#6b7280;text-align:center;line-height:1.6;">
                      We received a request to reset the password for your CountryBoy account.<br/>Click the button below to create a new password.
                    </p>

                    <!-- CTA Button -->
                    <div style="text-align:center;margin-bottom:28px;">
                      <a href="${resetLink}"
                        style="display:inline-block;padding:14px 36px;background:linear-gradient(135deg,#0f766e,#0891b2);color:#ffffff;text-decoration:none;border-radius:8px;font-size:15px;font-weight:700;letter-spacing:0.3px;">
                        Reset Password
                      </a>
                    </div>

                    <!-- Expiry warning -->
                    <table width="100%" cellpadding="0" cellspacing="0" style="background:#fffbeb;border:1px solid #fcd34d;border-radius:8px;margin-bottom:24px;">
                      <tr>
                        <td style="padding:14px 16px;">
                          <p style="margin:0;font-size:13px;color:#92400e;font-weight:700;">&#9888;&#65039; This link expires in 30 minutes</p>
                          <p style="margin:4px 0 0;font-size:12px;color:#b45309;line-height:1.5;">
                            After expiry, visit the login page and click "Forgot password" to request a new link.
                          </p>
                        </td>
                      </tr>
                    </table>

                    <!-- Divider -->
                    <hr style="border:none;border-top:1px solid #f3f4f6;margin:0 0 20px;" />

                    <!-- Security note -->
                    <p style="margin:0;font-size:12px;color:#9ca3af;line-height:1.6;text-align:center;">
                      If you didn't request a password reset, you can safely ignore this email.<br/>
                      Your password will remain unchanged.
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:24px 0 0;text-align:center;">
              <p style="margin:0;font-size:11px;color:#9ca3af;">
                &copy; 2025 CountryBoy Bus Ticketing System &bull; All rights reserved
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
  });
};
