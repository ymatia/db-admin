select a.application_short_name, a.application_name, pi.patch_level, decode(pi.status,'N','None','I','Installed','S','Shared')
from fnd_product_installations pi, fnd_application_vl a
where a.application_id=pi.application_id