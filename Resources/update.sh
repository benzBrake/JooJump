#!/bin/bash
for APP in potatso postern shadowrocket
do
	bash update_cn.sh ${APP}
	bash update_ncn.sh ${APP}
	bash update_video_ads.sh ${APP}
done