//มีไว้สร้างตัวแปร supabase กลาง เพื่อให้ทุกหน้าของแอปเรียกใช้ฐานข้อมูล Supabase ได้สะดวก
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;
