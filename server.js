const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// CONFIG - set your real secrets in environment variables
const TRANPORTAL_ID = process.env.TRANPORTAL_ID || '904zXK3D0cIHkuj';
const TRANPORTAL_PASSWORD = process.env.TRANPORTAL_PASSWORD || 'iO!Qwu5d#P9$87R';
const RESOURCE_KEY = process.env.RESOURCE_KEY || '52993662231652993662231652993662';
const NEOLAP_HOSTED_URL = 'https://securepayments.neoleap.com.sa/pg/payment/hosted.htm';
const NEOLAP_PAGELINK_PREFIX = 'https://securepayments.alrajhibank.com.sa/pg/paymentpage.htm?PaymentID=';

function encryptAes256Hex(plainText, keyStr) {
  let key = Buffer.from(keyStr, 'utf8');
  if (key.length !== 32) {
    const buff = Buffer.alloc(32);
    if (key.length < 32) key.copy(buff);
    else key = key.slice(0,32);
    key = buff;
  }
  const iv = Buffer.alloc(16, 0);
  const cipher = crypto.createCipheriv('aes-256-cbc', key, iv);
  let encrypted = cipher.update(plainText, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted.toUpperCase();
}

app.post('/create-payment', async (req, res) => {
  try {
    const { amt, currencyCode, errorURL, responseURL, trackId, action } = req.body;
    const reqObject = [{
      id: TRANPORTAL_ID,
      password: TRANPORTAL_PASSWORD,
      action: action || '1',
      currencyCode: currencyCode || '682',
      errorURL: errorURL || 'https://yourdomain.com/failure',
      responseURL: responseURL || 'https://yourdomain.com/success',
      trackId: trackId || (Date.now().toString()),
      amt: (typeof amt === 'number' ? amt.toFixed(2) : (amt || '1.00'))
    }];
    const reqJson = JSON.stringify(reqObject);
    const trandata = encryptAes256Hex(reqJson, RESOURCE_KEY);
    const form = new URLSearchParams();
    form.append('id', TRANPORTAL_ID);
    form.append('trandata', trandata);

    const r = await axios.post(NEOLAP_HOSTED_URL, form.toString(), { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    const bodyStr = (typeof r.data === 'string') ? r.data : JSON.stringify(r.data);
    const paymentIdMatch = bodyStr.match(/(\d{6,})/);
    let paymentUrl = null;
    if (paymentIdMatch) {
      paymentUrl = NEOLAP_PAGELINK_PREFIX + paymentIdMatch[1];
    } else {
      const urlMatch = bodyStr.match(/https?:\/\/[^\s'"]+/);
      if (urlMatch) paymentUrl = urlMatch[0];
    }
    if (!paymentUrl) return res.status(500).json({ ok:false, raw: bodyStr });
    return res.json({ ok:true, paymentUrl, raw: bodyStr });
  } catch (err) {
    return res.status(500).json({ ok:false, error: err.toString(), details: err.response?.data || null });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, ()=> console.log('Server listening on port', PORT));
