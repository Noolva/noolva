-- Update existing databases: global_icons table, seed rows, assets registry rows, App Studio menu.
-- Regenerated fragments: global_icons_seed_values.sql, global_icons_assets_feed.sql (from scripts/generate_global_icon_assets.py)

CREATE TABLE IF NOT EXISTS public.global_icons (
    id SERIAL PRIMARY KEY,
    icon_key TEXT NOT NULL,
    icon_path_web TEXT,
    icon_path_android TEXT,
    icon_path_ios TEXT,
    icon_path_macos TEXT
);

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'global_icons_icon_key_key'
    ) THEN
        ALTER TABLE public.global_icons ADD CONSTRAINT global_icons_icon_key_key UNIQUE (icon_key);
    END IF;
END $$;

INSERT INTO public.global_icons (icon_key, icon_path_web, icon_path_android, icon_path_ios, icon_path_macos)
VALUES
    ('home', 'public/global_icons/home.svg', 'public/global_icons/home.svg', 'public/global_icons/home.svg', 'public/global_icons/home.svg'),
    ('user', 'public/global_icons/user.svg', 'public/global_icons/user.svg', 'public/global_icons/user.svg', 'public/global_icons/user.svg'),
    ('users', 'public/global_icons/users.svg', 'public/global_icons/users.svg', 'public/global_icons/users.svg', 'public/global_icons/users.svg'),
    ('settings', 'public/global_icons/settings.svg', 'public/global_icons/settings.svg', 'public/global_icons/settings.svg', 'public/global_icons/settings.svg'),
    ('search', 'public/global_icons/search.svg', 'public/global_icons/search.svg', 'public/global_icons/search.svg', 'public/global_icons/search.svg'),
    ('menu', 'public/global_icons/menu.svg', 'public/global_icons/menu.svg', 'public/global_icons/menu.svg', 'public/global_icons/menu.svg'),
    ('close', 'public/global_icons/close.svg', 'public/global_icons/close.svg', 'public/global_icons/close.svg', 'public/global_icons/close.svg'),
    ('add', 'public/global_icons/add.svg', 'public/global_icons/add.svg', 'public/global_icons/add.svg', 'public/global_icons/add.svg'),
    ('edit', 'public/global_icons/edit.svg', 'public/global_icons/edit.svg', 'public/global_icons/edit.svg', 'public/global_icons/edit.svg'),
    ('delete', 'public/global_icons/delete.svg', 'public/global_icons/delete.svg', 'public/global_icons/delete.svg', 'public/global_icons/delete.svg'),
    ('save', 'public/global_icons/save.svg', 'public/global_icons/save.svg', 'public/global_icons/save.svg', 'public/global_icons/save.svg'),
    ('cancel', 'public/global_icons/cancel.svg', 'public/global_icons/cancel.svg', 'public/global_icons/cancel.svg', 'public/global_icons/cancel.svg'),
    ('check', 'public/global_icons/check.svg', 'public/global_icons/check.svg', 'public/global_icons/check.svg', 'public/global_icons/check.svg'),
    ('back', 'public/global_icons/back.svg', 'public/global_icons/back.svg', 'public/global_icons/back.svg', 'public/global_icons/back.svg'),
    ('forward', 'public/global_icons/forward.svg', 'public/global_icons/forward.svg', 'public/global_icons/forward.svg', 'public/global_icons/forward.svg'),
    ('refresh', 'public/global_icons/refresh.svg', 'public/global_icons/refresh.svg', 'public/global_icons/refresh.svg', 'public/global_icons/refresh.svg'),
    ('download', 'public/global_icons/download.svg', 'public/global_icons/download.svg', 'public/global_icons/download.svg', 'public/global_icons/download.svg'),
    ('upload', 'public/global_icons/upload.svg', 'public/global_icons/upload.svg', 'public/global_icons/upload.svg', 'public/global_icons/upload.svg'),
    ('share', 'public/global_icons/share.svg', 'public/global_icons/share.svg', 'public/global_icons/share.svg', 'public/global_icons/share.svg'),
    ('link', 'public/global_icons/link.svg', 'public/global_icons/link.svg', 'public/global_icons/link.svg', 'public/global_icons/link.svg'),
    ('copy', 'public/global_icons/copy.svg', 'public/global_icons/copy.svg', 'public/global_icons/copy.svg', 'public/global_icons/copy.svg'),
    ('filter', 'public/global_icons/filter.svg', 'public/global_icons/filter.svg', 'public/global_icons/filter.svg', 'public/global_icons/filter.svg'),
    ('sort', 'public/global_icons/sort.svg', 'public/global_icons/sort.svg', 'public/global_icons/sort.svg', 'public/global_icons/sort.svg'),
    ('calendar', 'public/global_icons/calendar.svg', 'public/global_icons/calendar.svg', 'public/global_icons/calendar.svg', 'public/global_icons/calendar.svg'),
    ('clock', 'public/global_icons/clock.svg', 'public/global_icons/clock.svg', 'public/global_icons/clock.svg', 'public/global_icons/clock.svg'),
    ('mail', 'public/global_icons/mail.svg', 'public/global_icons/mail.svg', 'public/global_icons/mail.svg', 'public/global_icons/mail.svg'),
    ('phone', 'public/global_icons/phone.svg', 'public/global_icons/phone.svg', 'public/global_icons/phone.svg', 'public/global_icons/phone.svg'),
    ('map', 'public/global_icons/map.svg', 'public/global_icons/map.svg', 'public/global_icons/map.svg', 'public/global_icons/map.svg'),
    ('location', 'public/global_icons/location.svg', 'public/global_icons/location.svg', 'public/global_icons/location.svg', 'public/global_icons/location.svg'),
    ('camera', 'public/global_icons/camera.svg', 'public/global_icons/camera.svg', 'public/global_icons/camera.svg', 'public/global_icons/camera.svg'),
    ('image', 'public/global_icons/image.svg', 'public/global_icons/image.svg', 'public/global_icons/image.svg', 'public/global_icons/image.svg'),
    ('file', 'public/global_icons/file.svg', 'public/global_icons/file.svg', 'public/global_icons/file.svg', 'public/global_icons/file.svg'),
    ('folder', 'public/global_icons/folder.svg', 'public/global_icons/folder.svg', 'public/global_icons/folder.svg', 'public/global_icons/folder.svg'),
    ('document', 'public/global_icons/document.svg', 'public/global_icons/document.svg', 'public/global_icons/document.svg', 'public/global_icons/document.svg'),
    ('print', 'public/global_icons/print.svg', 'public/global_icons/print.svg', 'public/global_icons/print.svg', 'public/global_icons/print.svg'),
    ('lock', 'public/global_icons/lock.svg', 'public/global_icons/lock.svg', 'public/global_icons/lock.svg', 'public/global_icons/lock.svg'),
    ('unlock', 'public/global_icons/unlock.svg', 'public/global_icons/unlock.svg', 'public/global_icons/unlock.svg', 'public/global_icons/unlock.svg'),
    ('key', 'public/global_icons/key.svg', 'public/global_icons/key.svg', 'public/global_icons/key.svg', 'public/global_icons/key.svg'),
    ('star', 'public/global_icons/star.svg', 'public/global_icons/star.svg', 'public/global_icons/star.svg', 'public/global_icons/star.svg'),
    ('heart', 'public/global_icons/heart.svg', 'public/global_icons/heart.svg', 'public/global_icons/heart.svg', 'public/global_icons/heart.svg'),
    ('bell', 'public/global_icons/bell.svg', 'public/global_icons/bell.svg', 'public/global_icons/bell.svg', 'public/global_icons/bell.svg'),
    ('flag', 'public/global_icons/flag.svg', 'public/global_icons/flag.svg', 'public/global_icons/flag.svg', 'public/global_icons/flag.svg'),
    ('bookmark', 'public/global_icons/bookmark.svg', 'public/global_icons/bookmark.svg', 'public/global_icons/bookmark.svg', 'public/global_icons/bookmark.svg'),
    ('tag', 'public/global_icons/tag.svg', 'public/global_icons/tag.svg', 'public/global_icons/tag.svg', 'public/global_icons/tag.svg'),
    ('cart', 'public/global_icons/cart.svg', 'public/global_icons/cart.svg', 'public/global_icons/cart.svg', 'public/global_icons/cart.svg'),
    ('shop', 'public/global_icons/shop.svg', 'public/global_icons/shop.svg', 'public/global_icons/shop.svg', 'public/global_icons/shop.svg'),
    ('credit_card', 'public/global_icons/credit_card.svg', 'public/global_icons/credit_card.svg', 'public/global_icons/credit_card.svg', 'public/global_icons/credit_card.svg'),
    ('dollar', 'public/global_icons/dollar.svg', 'public/global_icons/dollar.svg', 'public/global_icons/dollar.svg', 'public/global_icons/dollar.svg'),
    ('chart', 'public/global_icons/chart.svg', 'public/global_icons/chart.svg', 'public/global_icons/chart.svg', 'public/global_icons/chart.svg'),
    ('graph', 'public/global_icons/graph.svg', 'public/global_icons/graph.svg', 'public/global_icons/graph.svg', 'public/global_icons/graph.svg'),
    ('table', 'public/global_icons/table.svg', 'public/global_icons/table.svg', 'public/global_icons/table.svg', 'public/global_icons/table.svg'),
    ('list', 'public/global_icons/list.svg', 'public/global_icons/list.svg', 'public/global_icons/list.svg', 'public/global_icons/list.svg'),
    ('grid', 'public/global_icons/grid.svg', 'public/global_icons/grid.svg', 'public/global_icons/grid.svg', 'public/global_icons/grid.svg'),
    ('layout', 'public/global_icons/layout.svg', 'public/global_icons/layout.svg', 'public/global_icons/layout.svg', 'public/global_icons/layout.svg'),
    ('mobile', 'public/global_icons/mobile.svg', 'public/global_icons/mobile.svg', 'public/global_icons/mobile.svg', 'public/global_icons/mobile.svg'),
    ('tablet', 'public/global_icons/tablet.svg', 'public/global_icons/tablet.svg', 'public/global_icons/tablet.svg', 'public/global_icons/tablet.svg'),
    ('desktop', 'public/global_icons/desktop.svg', 'public/global_icons/desktop.svg', 'public/global_icons/desktop.svg', 'public/global_icons/desktop.svg'),
    ('wifi', 'public/global_icons/wifi.svg', 'public/global_icons/wifi.svg', 'public/global_icons/wifi.svg', 'public/global_icons/wifi.svg'),
    ('bluetooth', 'public/global_icons/bluetooth.svg', 'public/global_icons/bluetooth.svg', 'public/global_icons/bluetooth.svg', 'public/global_icons/bluetooth.svg'),
    ('battery', 'public/global_icons/battery.svg', 'public/global_icons/battery.svg', 'public/global_icons/battery.svg', 'public/global_icons/battery.svg'),
    ('volume', 'public/global_icons/volume.svg', 'public/global_icons/volume.svg', 'public/global_icons/volume.svg', 'public/global_icons/volume.svg'),
    ('play', 'public/global_icons/play.svg', 'public/global_icons/play.svg', 'public/global_icons/play.svg', 'public/global_icons/play.svg'),
    ('pause', 'public/global_icons/pause.svg', 'public/global_icons/pause.svg', 'public/global_icons/pause.svg', 'public/global_icons/pause.svg'),
    ('stop', 'public/global_icons/stop.svg', 'public/global_icons/stop.svg', 'public/global_icons/stop.svg', 'public/global_icons/stop.svg'),
    ('next_track', 'public/global_icons/next_track.svg', 'public/global_icons/next_track.svg', 'public/global_icons/next_track.svg', 'public/global_icons/next_track.svg'),
    ('previous_track', 'public/global_icons/previous_track.svg', 'public/global_icons/previous_track.svg', 'public/global_icons/previous_track.svg', 'public/global_icons/previous_track.svg'),
    ('info', 'public/global_icons/info.svg', 'public/global_icons/info.svg', 'public/global_icons/info.svg', 'public/global_icons/info.svg'),
    ('help', 'public/global_icons/help.svg', 'public/global_icons/help.svg', 'public/global_icons/help.svg', 'public/global_icons/help.svg'),
    ('warning', 'public/global_icons/warning.svg', 'public/global_icons/warning.svg', 'public/global_icons/warning.svg', 'public/global_icons/warning.svg'),
    ('error', 'public/global_icons/error.svg', 'public/global_icons/error.svg', 'public/global_icons/error.svg', 'public/global_icons/error.svg'),
    ('success', 'public/global_icons/success.svg', 'public/global_icons/success.svg', 'public/global_icons/success.svg', 'public/global_icons/success.svg'),
    ('question', 'public/global_icons/question.svg', 'public/global_icons/question.svg', 'public/global_icons/question.svg', 'public/global_icons/question.svg'),
    ('eye', 'public/global_icons/eye.svg', 'public/global_icons/eye.svg', 'public/global_icons/eye.svg', 'public/global_icons/eye.svg'),
    ('eye_off', 'public/global_icons/eye_off.svg', 'public/global_icons/eye_off.svg', 'public/global_icons/eye_off.svg', 'public/global_icons/eye_off.svg'),
    ('plus', 'public/global_icons/plus.svg', 'public/global_icons/plus.svg', 'public/global_icons/plus.svg', 'public/global_icons/plus.svg'),
    ('minus', 'public/global_icons/minus.svg', 'public/global_icons/minus.svg', 'public/global_icons/minus.svg', 'public/global_icons/minus.svg'),
    ('expand', 'public/global_icons/expand.svg', 'public/global_icons/expand.svg', 'public/global_icons/expand.svg', 'public/global_icons/expand.svg'),
    ('collapse', 'public/global_icons/collapse.svg', 'public/global_icons/collapse.svg', 'public/global_icons/collapse.svg', 'public/global_icons/collapse.svg'),
    ('more', 'public/global_icons/more.svg', 'public/global_icons/more.svg', 'public/global_icons/more.svg', 'public/global_icons/more.svg'),
    ('dots_vertical', 'public/global_icons/dots_vertical.svg', 'public/global_icons/dots_vertical.svg', 'public/global_icons/dots_vertical.svg', 'public/global_icons/dots_vertical.svg'),
    ('arrow_up', 'public/global_icons/arrow_up.svg', 'public/global_icons/arrow_up.svg', 'public/global_icons/arrow_up.svg', 'public/global_icons/arrow_up.svg'),
    ('arrow_down', 'public/global_icons/arrow_down.svg', 'public/global_icons/arrow_down.svg', 'public/global_icons/arrow_down.svg', 'public/global_icons/arrow_down.svg'),
    ('arrow_left', 'public/global_icons/arrow_left.svg', 'public/global_icons/arrow_left.svg', 'public/global_icons/arrow_left.svg', 'public/global_icons/arrow_left.svg'),
    ('arrow_right', 'public/global_icons/arrow_right.svg', 'public/global_icons/arrow_right.svg', 'public/global_icons/arrow_right.svg', 'public/global_icons/arrow_right.svg'),
    ('chevron_up', 'public/global_icons/chevron_up.svg', 'public/global_icons/chevron_up.svg', 'public/global_icons/chevron_up.svg', 'public/global_icons/chevron_up.svg'),
    ('chevron_down', 'public/global_icons/chevron_down.svg', 'public/global_icons/chevron_down.svg', 'public/global_icons/chevron_down.svg', 'public/global_icons/chevron_down.svg'),
    ('external_link', 'public/global_icons/external_link.svg', 'public/global_icons/external_link.svg', 'public/global_icons/external_link.svg', 'public/global_icons/external_link.svg'),
    ('attachment', 'public/global_icons/attachment.svg', 'public/global_icons/attachment.svg', 'public/global_icons/attachment.svg', 'public/global_icons/attachment.svg'),
    ('archive', 'public/global_icons/archive.svg', 'public/global_icons/archive.svg', 'public/global_icons/archive.svg', 'public/global_icons/archive.svg'),
    ('trash', 'public/global_icons/trash.svg', 'public/global_icons/trash.svg', 'public/global_icons/trash.svg', 'public/global_icons/trash.svg'),
    ('undo', 'public/global_icons/undo.svg', 'public/global_icons/undo.svg', 'public/global_icons/undo.svg', 'public/global_icons/undo.svg'),
    ('redo', 'public/global_icons/redo.svg', 'public/global_icons/redo.svg', 'public/global_icons/redo.svg', 'public/global_icons/redo.svg'),
    ('bold', 'public/global_icons/bold.svg', 'public/global_icons/bold.svg', 'public/global_icons/bold.svg', 'public/global_icons/bold.svg'),
    ('italic', 'public/global_icons/italic.svg', 'public/global_icons/italic.svg', 'public/global_icons/italic.svg', 'public/global_icons/italic.svg'),
    ('code', 'public/global_icons/code.svg', 'public/global_icons/code.svg', 'public/global_icons/code.svg', 'public/global_icons/code.svg'),
    ('globe', 'public/global_icons/globe.svg', 'public/global_icons/globe.svg', 'public/global_icons/globe.svg', 'public/global_icons/globe.svg'),
    ('cloud', 'public/global_icons/cloud.svg', 'public/global_icons/cloud.svg', 'public/global_icons/cloud.svg', 'public/global_icons/cloud.svg'),
    ('database', 'public/global_icons/database.svg', 'public/global_icons/database.svg', 'public/global_icons/database.svg', 'public/global_icons/database.svg'),
    ('server', 'public/global_icons/server.svg', 'public/global_icons/server.svg', 'public/global_icons/server.svg', 'public/global_icons/server.svg'),
    ('shield', 'public/global_icons/shield.svg', 'public/global_icons/shield.svg', 'public/global_icons/shield.svg', 'public/global_icons/shield.svg'),
    ('wrench', 'public/global_icons/wrench.svg', 'public/global_icons/wrench.svg', 'public/global_icons/wrench.svg', 'public/global_icons/wrench.svg'),
    ('tool', 'public/global_icons/tool.svg', 'public/global_icons/tool.svg', 'public/global_icons/tool.svg', 'public/global_icons/tool.svg'),
    ('sparkles', 'public/global_icons/sparkles.svg', 'public/global_icons/sparkles.svg', 'public/global_icons/sparkles.svg', 'public/global_icons/sparkles.svg'),
    ('robot', 'public/global_icons/robot.svg', 'public/global_icons/robot.svg', 'public/global_icons/robot.svg', 'public/global_icons/robot.svg'),
    ('chat', 'public/global_icons/chat.svg', 'public/global_icons/chat.svg', 'public/global_icons/chat.svg', 'public/global_icons/chat.svg'),
    ('message', 'public/global_icons/message.svg', 'public/global_icons/message.svg', 'public/global_icons/message.svg', 'public/global_icons/message.svg'),
    ('team', 'public/global_icons/team.svg', 'public/global_icons/team.svg', 'public/global_icons/team.svg', 'public/global_icons/team.svg'),
    ('building', 'public/global_icons/building.svg', 'public/global_icons/building.svg', 'public/global_icons/building.svg', 'public/global_icons/building.svg'),
    ('truck', 'public/global_icons/truck.svg', 'public/global_icons/truck.svg', 'public/global_icons/truck.svg', 'public/global_icons/truck.svg'),
    ('plane', 'public/global_icons/plane.svg', 'public/global_icons/plane.svg', 'public/global_icons/plane.svg', 'public/global_icons/plane.svg'),
    ('car', 'public/global_icons/car.svg', 'public/global_icons/car.svg', 'public/global_icons/car.svg', 'public/global_icons/car.svg'),
    ('coffee', 'public/global_icons/coffee.svg', 'public/global_icons/coffee.svg', 'public/global_icons/coffee.svg', 'public/global_icons/coffee.svg'),
    ('sun', 'public/global_icons/sun.svg', 'public/global_icons/sun.svg', 'public/global_icons/sun.svg', 'public/global_icons/sun.svg'),
    ('moon', 'public/global_icons/moon.svg', 'public/global_icons/moon.svg', 'public/global_icons/moon.svg', 'public/global_icons/moon.svg'),
    ('language', 'public/global_icons/language.svg', 'public/global_icons/language.svg', 'public/global_icons/language.svg', 'public/global_icons/language.svg'),
    ('log_in', 'public/global_icons/log_in.svg', 'public/global_icons/log_in.svg', 'public/global_icons/log_in.svg', 'public/global_icons/log_in.svg'),
    ('log_out', 'public/global_icons/log_out.svg', 'public/global_icons/log_out.svg', 'public/global_icons/log_out.svg', 'public/global_icons/log_out.svg'),
    ('profile', 'public/global_icons/profile.svg', 'public/global_icons/profile.svg', 'public/global_icons/profile.svg', 'public/global_icons/profile.svg'),
    ('notification', 'public/global_icons/notification.svg', 'public/global_icons/notification.svg', 'public/global_icons/notification.svg', 'public/global_icons/notification.svg'),
    ('dashboard', 'public/global_icons/dashboard.svg', 'public/global_icons/dashboard.svg', 'public/global_icons/dashboard.svg', 'public/global_icons/dashboard.svg'),
    ('activity', 'public/global_icons/activity.svg', 'public/global_icons/activity.svg', 'public/global_icons/activity.svg', 'public/global_icons/activity.svg'),
    ('layers', 'public/global_icons/layers.svg', 'public/global_icons/layers.svg', 'public/global_icons/layers.svg', 'public/global_icons/layers.svg'),
    ('compass', 'public/global_icons/compass.svg', 'public/global_icons/compass.svg', 'public/global_icons/compass.svg', 'public/global_icons/compass.svg'),
    ('target', 'public/global_icons/target.svg', 'public/global_icons/target.svg', 'public/global_icons/target.svg', 'public/global_icons/target.svg'),
    ('award', 'public/global_icons/award.svg', 'public/global_icons/award.svg', 'public/global_icons/award.svg', 'public/global_icons/award.svg'),
    ('gift', 'public/global_icons/gift.svg', 'public/global_icons/gift.svg', 'public/global_icons/gift.svg', 'public/global_icons/gift.svg'),
    ('megaphone', 'public/global_icons/megaphone.svg', 'public/global_icons/megaphone.svg', 'public/global_icons/megaphone.svg', 'public/global_icons/megaphone.svg'),
    ('puzzle', 'public/global_icons/puzzle.svg', 'public/global_icons/puzzle.svg', 'public/global_icons/puzzle.svg', 'public/global_icons/puzzle.svg'),
    ('brush', 'public/global_icons/brush.svg', 'public/global_icons/brush.svg', 'public/global_icons/brush.svg', 'public/global_icons/brush.svg'),
    ('crop', 'public/global_icons/crop.svg', 'public/global_icons/crop.svg', 'public/global_icons/crop.svg', 'public/global_icons/crop.svg'),
    ('adjust', 'public/global_icons/adjust.svg', 'public/global_icons/adjust.svg', 'public/global_icons/adjust.svg', 'public/global_icons/adjust.svg'),
    ('zoom_in', 'public/global_icons/zoom_in.svg', 'public/global_icons/zoom_in.svg', 'public/global_icons/zoom_in.svg', 'public/global_icons/zoom_in.svg'),
    ('zoom_out', 'public/global_icons/zoom_out.svg', 'public/global_icons/zoom_out.svg', 'public/global_icons/zoom_out.svg', 'public/global_icons/zoom_out.svg'),
    ('inbox', 'public/global_icons/inbox.svg', 'public/global_icons/inbox.svg', 'public/global_icons/inbox.svg', 'public/global_icons/inbox.svg'),
    ('send', 'public/global_icons/send.svg', 'public/global_icons/send.svg', 'public/global_icons/send.svg', 'public/global_icons/send.svg'),
    ('reply', 'public/global_icons/reply.svg', 'public/global_icons/reply.svg', 'public/global_icons/reply.svg', 'public/global_icons/reply.svg'),
    ('forward_mail', 'public/global_icons/forward_mail.svg', 'public/global_icons/forward_mail.svg', 'public/global_icons/forward_mail.svg', 'public/global_icons/forward_mail.svg'),
    ('folder_open', 'public/global_icons/folder_open.svg', 'public/global_icons/folder_open.svg', 'public/global_icons/folder_open.svg', 'public/global_icons/folder_open.svg'),
    ('note', 'public/global_icons/note.svg', 'public/global_icons/note.svg', 'public/global_icons/note.svg', 'public/global_icons/note.svg'),
    ('pin', 'public/global_icons/pin.svg', 'public/global_icons/pin.svg', 'public/global_icons/pin.svg', 'public/global_icons/pin.svg'),
    ('unpin', 'public/global_icons/unpin.svg', 'public/global_icons/unpin.svg', 'public/global_icons/unpin.svg', 'public/global_icons/unpin.svg'),
    ('history', 'public/global_icons/history.svg', 'public/global_icons/history.svg', 'public/global_icons/history.svg', 'public/global_icons/history.svg'),
    ('sync', 'public/global_icons/sync.svg', 'public/global_icons/sync.svg', 'public/global_icons/sync.svg', 'public/global_icons/sync.svg'),
    ('import_icon', 'public/global_icons/import_icon.svg', 'public/global_icons/import_icon.svg', 'public/global_icons/import_icon.svg', 'public/global_icons/import_icon.svg'),
    ('export_icon', 'public/global_icons/export_icon.svg', 'public/global_icons/export_icon.svg', 'public/global_icons/export_icon.svg', 'public/global_icons/export_icon.svg'),
    ('template', 'public/global_icons/template.svg', 'public/global_icons/template.svg', 'public/global_icons/template.svg', 'public/global_icons/template.svg'),
    ('workflow', 'public/global_icons/workflow.svg', 'public/global_icons/workflow.svg', 'public/global_icons/workflow.svg', 'public/global_icons/workflow.svg'),
    ('api', 'public/global_icons/api.svg', 'public/global_icons/api.svg', 'public/global_icons/api.svg', 'public/global_icons/api.svg'),
    ('webhook', 'public/global_icons/webhook.svg', 'public/global_icons/webhook.svg', 'public/global_icons/webhook.svg', 'public/global_icons/webhook.svg'),
    ('terminal', 'public/global_icons/terminal.svg', 'public/global_icons/terminal.svg', 'public/global_icons/terminal.svg', 'public/global_icons/terminal.svg')
ON CONFLICT (icon_key) DO NOTHING;

DO $$
DECLARE
    v_system_user_id INTEGER;
BEGIN
    SELECT user_id INTO v_system_user_id FROM public.users WHERE is_super_admin = TRUE LIMIT 1;
    INSERT INTO public.assets (file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    SELECT * FROM (VALUES
        ('home.svg', 'home.svg', 'image/svg+xml', 'global_icons/home.svg', TRUE, NULL, v_system_user_id),
        ('user.svg', 'user.svg', 'image/svg+xml', 'global_icons/user.svg', TRUE, NULL, v_system_user_id),
        ('users.svg', 'users.svg', 'image/svg+xml', 'global_icons/users.svg', TRUE, NULL, v_system_user_id),
        ('settings.svg', 'settings.svg', 'image/svg+xml', 'global_icons/settings.svg', TRUE, NULL, v_system_user_id),
        ('search.svg', 'search.svg', 'image/svg+xml', 'global_icons/search.svg', TRUE, NULL, v_system_user_id),
        ('menu.svg', 'menu.svg', 'image/svg+xml', 'global_icons/menu.svg', TRUE, NULL, v_system_user_id),
        ('close.svg', 'close.svg', 'image/svg+xml', 'global_icons/close.svg', TRUE, NULL, v_system_user_id),
        ('add.svg', 'add.svg', 'image/svg+xml', 'global_icons/add.svg', TRUE, NULL, v_system_user_id),
        ('edit.svg', 'edit.svg', 'image/svg+xml', 'global_icons/edit.svg', TRUE, NULL, v_system_user_id),
        ('delete.svg', 'delete.svg', 'image/svg+xml', 'global_icons/delete.svg', TRUE, NULL, v_system_user_id),
        ('save.svg', 'save.svg', 'image/svg+xml', 'global_icons/save.svg', TRUE, NULL, v_system_user_id),
        ('cancel.svg', 'cancel.svg', 'image/svg+xml', 'global_icons/cancel.svg', TRUE, NULL, v_system_user_id),
        ('check.svg', 'check.svg', 'image/svg+xml', 'global_icons/check.svg', TRUE, NULL, v_system_user_id),
        ('back.svg', 'back.svg', 'image/svg+xml', 'global_icons/back.svg', TRUE, NULL, v_system_user_id),
        ('forward.svg', 'forward.svg', 'image/svg+xml', 'global_icons/forward.svg', TRUE, NULL, v_system_user_id),
        ('refresh.svg', 'refresh.svg', 'image/svg+xml', 'global_icons/refresh.svg', TRUE, NULL, v_system_user_id),
        ('download.svg', 'download.svg', 'image/svg+xml', 'global_icons/download.svg', TRUE, NULL, v_system_user_id),
        ('upload.svg', 'upload.svg', 'image/svg+xml', 'global_icons/upload.svg', TRUE, NULL, v_system_user_id),
        ('share.svg', 'share.svg', 'image/svg+xml', 'global_icons/share.svg', TRUE, NULL, v_system_user_id),
        ('link.svg', 'link.svg', 'image/svg+xml', 'global_icons/link.svg', TRUE, NULL, v_system_user_id),
        ('copy.svg', 'copy.svg', 'image/svg+xml', 'global_icons/copy.svg', TRUE, NULL, v_system_user_id),
        ('filter.svg', 'filter.svg', 'image/svg+xml', 'global_icons/filter.svg', TRUE, NULL, v_system_user_id),
        ('sort.svg', 'sort.svg', 'image/svg+xml', 'global_icons/sort.svg', TRUE, NULL, v_system_user_id),
        ('calendar.svg', 'calendar.svg', 'image/svg+xml', 'global_icons/calendar.svg', TRUE, NULL, v_system_user_id),
        ('clock.svg', 'clock.svg', 'image/svg+xml', 'global_icons/clock.svg', TRUE, NULL, v_system_user_id),
        ('mail.svg', 'mail.svg', 'image/svg+xml', 'global_icons/mail.svg', TRUE, NULL, v_system_user_id),
        ('phone.svg', 'phone.svg', 'image/svg+xml', 'global_icons/phone.svg', TRUE, NULL, v_system_user_id),
        ('map.svg', 'map.svg', 'image/svg+xml', 'global_icons/map.svg', TRUE, NULL, v_system_user_id),
        ('location.svg', 'location.svg', 'image/svg+xml', 'global_icons/location.svg', TRUE, NULL, v_system_user_id),
        ('camera.svg', 'camera.svg', 'image/svg+xml', 'global_icons/camera.svg', TRUE, NULL, v_system_user_id),
        ('image.svg', 'image.svg', 'image/svg+xml', 'global_icons/image.svg', TRUE, NULL, v_system_user_id),
        ('file.svg', 'file.svg', 'image/svg+xml', 'global_icons/file.svg', TRUE, NULL, v_system_user_id),
        ('folder.svg', 'folder.svg', 'image/svg+xml', 'global_icons/folder.svg', TRUE, NULL, v_system_user_id),
        ('document.svg', 'document.svg', 'image/svg+xml', 'global_icons/document.svg', TRUE, NULL, v_system_user_id),
        ('print.svg', 'print.svg', 'image/svg+xml', 'global_icons/print.svg', TRUE, NULL, v_system_user_id),
        ('lock.svg', 'lock.svg', 'image/svg+xml', 'global_icons/lock.svg', TRUE, NULL, v_system_user_id),
        ('unlock.svg', 'unlock.svg', 'image/svg+xml', 'global_icons/unlock.svg', TRUE, NULL, v_system_user_id),
        ('key.svg', 'key.svg', 'image/svg+xml', 'global_icons/key.svg', TRUE, NULL, v_system_user_id),
        ('star.svg', 'star.svg', 'image/svg+xml', 'global_icons/star.svg', TRUE, NULL, v_system_user_id),
        ('heart.svg', 'heart.svg', 'image/svg+xml', 'global_icons/heart.svg', TRUE, NULL, v_system_user_id),
        ('bell.svg', 'bell.svg', 'image/svg+xml', 'global_icons/bell.svg', TRUE, NULL, v_system_user_id),
        ('flag.svg', 'flag.svg', 'image/svg+xml', 'global_icons/flag.svg', TRUE, NULL, v_system_user_id),
        ('bookmark.svg', 'bookmark.svg', 'image/svg+xml', 'global_icons/bookmark.svg', TRUE, NULL, v_system_user_id),
        ('tag.svg', 'tag.svg', 'image/svg+xml', 'global_icons/tag.svg', TRUE, NULL, v_system_user_id),
        ('cart.svg', 'cart.svg', 'image/svg+xml', 'global_icons/cart.svg', TRUE, NULL, v_system_user_id),
        ('shop.svg', 'shop.svg', 'image/svg+xml', 'global_icons/shop.svg', TRUE, NULL, v_system_user_id),
        ('credit_card.svg', 'credit_card.svg', 'image/svg+xml', 'global_icons/credit_card.svg', TRUE, NULL, v_system_user_id),
        ('dollar.svg', 'dollar.svg', 'image/svg+xml', 'global_icons/dollar.svg', TRUE, NULL, v_system_user_id),
        ('chart.svg', 'chart.svg', 'image/svg+xml', 'global_icons/chart.svg', TRUE, NULL, v_system_user_id),
        ('graph.svg', 'graph.svg', 'image/svg+xml', 'global_icons/graph.svg', TRUE, NULL, v_system_user_id),
        ('table.svg', 'table.svg', 'image/svg+xml', 'global_icons/table.svg', TRUE, NULL, v_system_user_id),
        ('list.svg', 'list.svg', 'image/svg+xml', 'global_icons/list.svg', TRUE, NULL, v_system_user_id),
        ('grid.svg', 'grid.svg', 'image/svg+xml', 'global_icons/grid.svg', TRUE, NULL, v_system_user_id),
        ('layout.svg', 'layout.svg', 'image/svg+xml', 'global_icons/layout.svg', TRUE, NULL, v_system_user_id),
        ('mobile.svg', 'mobile.svg', 'image/svg+xml', 'global_icons/mobile.svg', TRUE, NULL, v_system_user_id),
        ('tablet.svg', 'tablet.svg', 'image/svg+xml', 'global_icons/tablet.svg', TRUE, NULL, v_system_user_id),
        ('desktop.svg', 'desktop.svg', 'image/svg+xml', 'global_icons/desktop.svg', TRUE, NULL, v_system_user_id),
        ('wifi.svg', 'wifi.svg', 'image/svg+xml', 'global_icons/wifi.svg', TRUE, NULL, v_system_user_id),
        ('bluetooth.svg', 'bluetooth.svg', 'image/svg+xml', 'global_icons/bluetooth.svg', TRUE, NULL, v_system_user_id),
        ('battery.svg', 'battery.svg', 'image/svg+xml', 'global_icons/battery.svg', TRUE, NULL, v_system_user_id),
        ('volume.svg', 'volume.svg', 'image/svg+xml', 'global_icons/volume.svg', TRUE, NULL, v_system_user_id),
        ('play.svg', 'play.svg', 'image/svg+xml', 'global_icons/play.svg', TRUE, NULL, v_system_user_id),
        ('pause.svg', 'pause.svg', 'image/svg+xml', 'global_icons/pause.svg', TRUE, NULL, v_system_user_id),
        ('stop.svg', 'stop.svg', 'image/svg+xml', 'global_icons/stop.svg', TRUE, NULL, v_system_user_id),
        ('next_track.svg', 'next_track.svg', 'image/svg+xml', 'global_icons/next_track.svg', TRUE, NULL, v_system_user_id),
        ('previous_track.svg', 'previous_track.svg', 'image/svg+xml', 'global_icons/previous_track.svg', TRUE, NULL, v_system_user_id),
        ('info.svg', 'info.svg', 'image/svg+xml', 'global_icons/info.svg', TRUE, NULL, v_system_user_id),
        ('help.svg', 'help.svg', 'image/svg+xml', 'global_icons/help.svg', TRUE, NULL, v_system_user_id),
        ('warning.svg', 'warning.svg', 'image/svg+xml', 'global_icons/warning.svg', TRUE, NULL, v_system_user_id),
        ('error.svg', 'error.svg', 'image/svg+xml', 'global_icons/error.svg', TRUE, NULL, v_system_user_id),
        ('success.svg', 'success.svg', 'image/svg+xml', 'global_icons/success.svg', TRUE, NULL, v_system_user_id),
        ('question.svg', 'question.svg', 'image/svg+xml', 'global_icons/question.svg', TRUE, NULL, v_system_user_id),
        ('eye.svg', 'eye.svg', 'image/svg+xml', 'global_icons/eye.svg', TRUE, NULL, v_system_user_id),
        ('eye_off.svg', 'eye_off.svg', 'image/svg+xml', 'global_icons/eye_off.svg', TRUE, NULL, v_system_user_id),
        ('plus.svg', 'plus.svg', 'image/svg+xml', 'global_icons/plus.svg', TRUE, NULL, v_system_user_id),
        ('minus.svg', 'minus.svg', 'image/svg+xml', 'global_icons/minus.svg', TRUE, NULL, v_system_user_id),
        ('expand.svg', 'expand.svg', 'image/svg+xml', 'global_icons/expand.svg', TRUE, NULL, v_system_user_id),
        ('collapse.svg', 'collapse.svg', 'image/svg+xml', 'global_icons/collapse.svg', TRUE, NULL, v_system_user_id),
        ('more.svg', 'more.svg', 'image/svg+xml', 'global_icons/more.svg', TRUE, NULL, v_system_user_id),
        ('dots_vertical.svg', 'dots_vertical.svg', 'image/svg+xml', 'global_icons/dots_vertical.svg', TRUE, NULL, v_system_user_id),
        ('arrow_up.svg', 'arrow_up.svg', 'image/svg+xml', 'global_icons/arrow_up.svg', TRUE, NULL, v_system_user_id),
        ('arrow_down.svg', 'arrow_down.svg', 'image/svg+xml', 'global_icons/arrow_down.svg', TRUE, NULL, v_system_user_id),
        ('arrow_left.svg', 'arrow_left.svg', 'image/svg+xml', 'global_icons/arrow_left.svg', TRUE, NULL, v_system_user_id),
        ('arrow_right.svg', 'arrow_right.svg', 'image/svg+xml', 'global_icons/arrow_right.svg', TRUE, NULL, v_system_user_id),
        ('chevron_up.svg', 'chevron_up.svg', 'image/svg+xml', 'global_icons/chevron_up.svg', TRUE, NULL, v_system_user_id),
        ('chevron_down.svg', 'chevron_down.svg', 'image/svg+xml', 'global_icons/chevron_down.svg', TRUE, NULL, v_system_user_id),
        ('external_link.svg', 'external_link.svg', 'image/svg+xml', 'global_icons/external_link.svg', TRUE, NULL, v_system_user_id),
        ('attachment.svg', 'attachment.svg', 'image/svg+xml', 'global_icons/attachment.svg', TRUE, NULL, v_system_user_id),
        ('archive.svg', 'archive.svg', 'image/svg+xml', 'global_icons/archive.svg', TRUE, NULL, v_system_user_id),
        ('trash.svg', 'trash.svg', 'image/svg+xml', 'global_icons/trash.svg', TRUE, NULL, v_system_user_id),
        ('undo.svg', 'undo.svg', 'image/svg+xml', 'global_icons/undo.svg', TRUE, NULL, v_system_user_id),
        ('redo.svg', 'redo.svg', 'image/svg+xml', 'global_icons/redo.svg', TRUE, NULL, v_system_user_id),
        ('bold.svg', 'bold.svg', 'image/svg+xml', 'global_icons/bold.svg', TRUE, NULL, v_system_user_id),
        ('italic.svg', 'italic.svg', 'image/svg+xml', 'global_icons/italic.svg', TRUE, NULL, v_system_user_id),
        ('code.svg', 'code.svg', 'image/svg+xml', 'global_icons/code.svg', TRUE, NULL, v_system_user_id),
        ('globe.svg', 'globe.svg', 'image/svg+xml', 'global_icons/globe.svg', TRUE, NULL, v_system_user_id),
        ('cloud.svg', 'cloud.svg', 'image/svg+xml', 'global_icons/cloud.svg', TRUE, NULL, v_system_user_id),
        ('database.svg', 'database.svg', 'image/svg+xml', 'global_icons/database.svg', TRUE, NULL, v_system_user_id),
        ('server.svg', 'server.svg', 'image/svg+xml', 'global_icons/server.svg', TRUE, NULL, v_system_user_id),
        ('shield.svg', 'shield.svg', 'image/svg+xml', 'global_icons/shield.svg', TRUE, NULL, v_system_user_id),
        ('wrench.svg', 'wrench.svg', 'image/svg+xml', 'global_icons/wrench.svg', TRUE, NULL, v_system_user_id),
        ('tool.svg', 'tool.svg', 'image/svg+xml', 'global_icons/tool.svg', TRUE, NULL, v_system_user_id),
        ('sparkles.svg', 'sparkles.svg', 'image/svg+xml', 'global_icons/sparkles.svg', TRUE, NULL, v_system_user_id),
        ('robot.svg', 'robot.svg', 'image/svg+xml', 'global_icons/robot.svg', TRUE, NULL, v_system_user_id),
        ('chat.svg', 'chat.svg', 'image/svg+xml', 'global_icons/chat.svg', TRUE, NULL, v_system_user_id),
        ('message.svg', 'message.svg', 'image/svg+xml', 'global_icons/message.svg', TRUE, NULL, v_system_user_id),
        ('team.svg', 'team.svg', 'image/svg+xml', 'global_icons/team.svg', TRUE, NULL, v_system_user_id),
        ('building.svg', 'building.svg', 'image/svg+xml', 'global_icons/building.svg', TRUE, NULL, v_system_user_id),
        ('truck.svg', 'truck.svg', 'image/svg+xml', 'global_icons/truck.svg', TRUE, NULL, v_system_user_id),
        ('plane.svg', 'plane.svg', 'image/svg+xml', 'global_icons/plane.svg', TRUE, NULL, v_system_user_id),
        ('car.svg', 'car.svg', 'image/svg+xml', 'global_icons/car.svg', TRUE, NULL, v_system_user_id),
        ('coffee.svg', 'coffee.svg', 'image/svg+xml', 'global_icons/coffee.svg', TRUE, NULL, v_system_user_id),
        ('sun.svg', 'sun.svg', 'image/svg+xml', 'global_icons/sun.svg', TRUE, NULL, v_system_user_id),
        ('moon.svg', 'moon.svg', 'image/svg+xml', 'global_icons/moon.svg', TRUE, NULL, v_system_user_id),
        ('language.svg', 'language.svg', 'image/svg+xml', 'global_icons/language.svg', TRUE, NULL, v_system_user_id),
        ('log_in.svg', 'log_in.svg', 'image/svg+xml', 'global_icons/log_in.svg', TRUE, NULL, v_system_user_id),
        ('log_out.svg', 'log_out.svg', 'image/svg+xml', 'global_icons/log_out.svg', TRUE, NULL, v_system_user_id),
        ('profile.svg', 'profile.svg', 'image/svg+xml', 'global_icons/profile.svg', TRUE, NULL, v_system_user_id),
        ('notification.svg', 'notification.svg', 'image/svg+xml', 'global_icons/notification.svg', TRUE, NULL, v_system_user_id),
        ('dashboard.svg', 'dashboard.svg', 'image/svg+xml', 'global_icons/dashboard.svg', TRUE, NULL, v_system_user_id),
        ('activity.svg', 'activity.svg', 'image/svg+xml', 'global_icons/activity.svg', TRUE, NULL, v_system_user_id),
        ('layers.svg', 'layers.svg', 'image/svg+xml', 'global_icons/layers.svg', TRUE, NULL, v_system_user_id),
        ('compass.svg', 'compass.svg', 'image/svg+xml', 'global_icons/compass.svg', TRUE, NULL, v_system_user_id),
        ('target.svg', 'target.svg', 'image/svg+xml', 'global_icons/target.svg', TRUE, NULL, v_system_user_id),
        ('award.svg', 'award.svg', 'image/svg+xml', 'global_icons/award.svg', TRUE, NULL, v_system_user_id),
        ('gift.svg', 'gift.svg', 'image/svg+xml', 'global_icons/gift.svg', TRUE, NULL, v_system_user_id),
        ('megaphone.svg', 'megaphone.svg', 'image/svg+xml', 'global_icons/megaphone.svg', TRUE, NULL, v_system_user_id),
        ('puzzle.svg', 'puzzle.svg', 'image/svg+xml', 'global_icons/puzzle.svg', TRUE, NULL, v_system_user_id),
        ('brush.svg', 'brush.svg', 'image/svg+xml', 'global_icons/brush.svg', TRUE, NULL, v_system_user_id),
        ('crop.svg', 'crop.svg', 'image/svg+xml', 'global_icons/crop.svg', TRUE, NULL, v_system_user_id),
        ('adjust.svg', 'adjust.svg', 'image/svg+xml', 'global_icons/adjust.svg', TRUE, NULL, v_system_user_id),
        ('zoom_in.svg', 'zoom_in.svg', 'image/svg+xml', 'global_icons/zoom_in.svg', TRUE, NULL, v_system_user_id),
        ('zoom_out.svg', 'zoom_out.svg', 'image/svg+xml', 'global_icons/zoom_out.svg', TRUE, NULL, v_system_user_id),
        ('inbox.svg', 'inbox.svg', 'image/svg+xml', 'global_icons/inbox.svg', TRUE, NULL, v_system_user_id),
        ('send.svg', 'send.svg', 'image/svg+xml', 'global_icons/send.svg', TRUE, NULL, v_system_user_id),
        ('reply.svg', 'reply.svg', 'image/svg+xml', 'global_icons/reply.svg', TRUE, NULL, v_system_user_id),
        ('forward_mail.svg', 'forward_mail.svg', 'image/svg+xml', 'global_icons/forward_mail.svg', TRUE, NULL, v_system_user_id),
        ('folder_open.svg', 'folder_open.svg', 'image/svg+xml', 'global_icons/folder_open.svg', TRUE, NULL, v_system_user_id),
        ('note.svg', 'note.svg', 'image/svg+xml', 'global_icons/note.svg', TRUE, NULL, v_system_user_id),
        ('pin.svg', 'pin.svg', 'image/svg+xml', 'global_icons/pin.svg', TRUE, NULL, v_system_user_id),
        ('unpin.svg', 'unpin.svg', 'image/svg+xml', 'global_icons/unpin.svg', TRUE, NULL, v_system_user_id),
        ('history.svg', 'history.svg', 'image/svg+xml', 'global_icons/history.svg', TRUE, NULL, v_system_user_id),
        ('sync.svg', 'sync.svg', 'image/svg+xml', 'global_icons/sync.svg', TRUE, NULL, v_system_user_id),
        ('import_icon.svg', 'import_icon.svg', 'image/svg+xml', 'global_icons/import_icon.svg', TRUE, NULL, v_system_user_id),
        ('export_icon.svg', 'export_icon.svg', 'image/svg+xml', 'global_icons/export_icon.svg', TRUE, NULL, v_system_user_id),
        ('template.svg', 'template.svg', 'image/svg+xml', 'global_icons/template.svg', TRUE, NULL, v_system_user_id),
        ('workflow.svg', 'workflow.svg', 'image/svg+xml', 'global_icons/workflow.svg', TRUE, NULL, v_system_user_id),
        ('api.svg', 'api.svg', 'image/svg+xml', 'global_icons/api.svg', TRUE, NULL, v_system_user_id),
        ('webhook.svg', 'webhook.svg', 'image/svg+xml', 'global_icons/webhook.svg', TRUE, NULL, v_system_user_id),
        ('terminal.svg', 'terminal.svg', 'image/svg+xml', 'global_icons/terminal.svg', TRUE, NULL, v_system_user_id)
    ) AS t(file_name, original_name, mime_type, storage_path, is_public, company_id, uploaded_by)
    WHERE NOT EXISTS (
        SELECT 1 FROM public.assets a WHERE a.storage_path = t.storage_path AND a.company_id IS NULL
    );
END $$;

DO $$

DECLARE

    studio_id INT;

    uid INT;

BEGIN

    SELECT app_id INTO studio_id FROM public.apps WHERE app_name = 'app_studio' LIMIT 1;

    IF studio_id IS NULL THEN

        RAISE NOTICE 'app_studio app not found; skip menu';

        RETURN;

    END IF;

    SELECT user_id INTO uid FROM public.users WHERE is_super_admin = TRUE LIMIT 1;

    IF NOT EXISTS (

        SELECT 1 FROM public.menus WHERE app_id = studio_id AND route_path = 'studio_global_icons'

    ) THEN

        INSERT INTO public.menus (

            menu_title, parent_id, type, route_path, icon, app_id, scope, is_builtin, order_no, created_by

        ) VALUES (

            'Global icons', NULL, 'item', 'studio_global_icons', 'picture',

            studio_id, 'saas', TRUE, 105, uid

        );

    END IF;

END $$;
