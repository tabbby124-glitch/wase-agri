# ربط WAS الزراعية مع WhatsApp عبر n8n

## ما الذي يرسله النظام؟
- تسجيل عملية زراعية جديدة.
- تسجيل حصاد جديد.
- فتح/توليد تقرير حقل.
- إضافة صور إلى عملية موجودة؛ تُرفع الصور إلى مخزن Supabase الخاص ثم يرسل n8n الصور إلى واتساب.

لا تُرسل إضافة الحقول أو النسخ الاحتياطية أو الحذف أو التعديلات غير المحددة ضمن اختيار المستخدم.

## البنية
WAS PWA → Supabase `farm_activity` → Supabase Database Webhook → n8n → WhatsApp Cloud API.

الأحداث تُحفظ في طابور محلي عند انقطاع الإنترنت، ثم تُرفع بعد عودة الاتصال وتوفر جلسة دخول سحابية.

## ملف الاستيراد
استورد `WAS_WhatsApp_Notifications.json` من n8n: Workflows → Import from File.

## إعداد n8n
1. افتح عقدة **Supabase Farm Activity** وانسخ Production URL بعد نشر/تفعيل الـ workflow.
2. في عقدة **Filter and format WAS alert** غيّر:
   - `hookSecret`: قيمة عشوائية طويلة.
   - `whatsappTo`: رقمك بصيغة دولية دون + أو مسافات، مثال شكلي فقط: `249XXXXXXXXX`.
   - `whatsappPhoneNumberId`: Phone Number ID من Meta.
3. في عقدتي **Send WhatsApp text** و **Send WhatsApp image** استبدل `REPLACE_WITH_META_WHATSAPP_ACCESS_TOKEN` برمز WhatsApp Cloud API.
4. في عقدة **Create private photo link** استبدل `REPLACE_WITH_SUPABASE_SECRET_KEY` بمفتاح Supabase Secret/Service Role. هذا المفتاح يبقى داخل n8n فقط ولا يوضع في تطبيق الهاتف أو GitHub.
5. انشر/فعّل الـ workflow واختبره.

## إعداد Supabase Database Webhook
بعد توفير Production URL من n8n:
1. افتح Supabase → Integrations → Database Webhooks.
2. أنشئ webhook باسم `was_to_n8n_whatsapp`.
3. الجدول: `public.farm_activity`.
4. الحدث: INSERT فقط.
5. Method: POST، والـ URL: Production URL المنسوخ من n8n.
6. أضف Header:
   - Name: `x-was-hook-secret`
   - Value: نفس `hookSecret` في عقدة Code.
7. احفظ الإعداد.

## متطلبات Meta المهمة
- يجب إعداد WhatsApp Business Cloud API ورقم إرسال معتمد وAccess Token صالح.
- رقم المستلم بصيغة دولية.
- رسائل التنبيه التي يبدأها النشاط التجاري قد تتطلب قالب Utility معتمداً إذا لم تكن نافذة خدمة العميل (24 ساعة) مفتوحة. لا تعتبر نجاح استدعاء n8n ضماناً لوصول الرسالة؛ افحص نتيجة Meta وحالة الرسالة.

## التحقق
1. سجّل الدخول في WAS بحساب سحابي.
2. سجّل عملية زراعية تجريبية.
3. تحقق من ظهور صف جديد في `farm_activity` بنوع `operation`.
4. تحقق من وصول تنفيذ إلى n8n ثم استجابة Meta.
5. أضف صورة للعملية وتحقق من وجود `photo_paths` ثم وصول الصورة.

## الأمان
- لا تضع Supabase Secret/Service Role Key أو WhatsApp Access Token في كود WAS.
- لا ترفع ملف workflow بعد استبدال placeholders بمفاتيح حقيقية إلى مستودع عام.
- استخدم رقمك الشخصي كمستلم فقط؛ لا تُرسل إشعارات إلى أرقام أخرى.
