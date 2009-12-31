select ap.patch_name, ap.patch_type, max(ap.creation_date), 
dbax_dbadmin_app_info.get_moudles_by_patch_name(ap.patch_name)
from applsys.ad_applied_patches ap
group by ap.patch_name, ap.patch_type

