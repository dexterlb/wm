#!/usr/bin/env python3
# this is a heavily hacked version of Statnot that only 
# prints notifications to stdout, and has all the other
# bloat cut out.

#
#   statnot - Status and Notifications
#
#   Lightweight notification-(to-become)-deamon intended to be used
#   with lightweight WMs, like dwm.
#   Receives Desktop Notifications (including libnotify / notify-send)
#   See: http://www.galago-project.org/specs/notification/0.9/index.html
#
#   Note: VERY early prototype, to get feedback.
#
#   Copyright (c) 2009-2011 by the authors
#   http://code.k2h.se
#   Please report bugs or feature requests by e-mail.
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import dbus
import dbus.service
import dbus.mainloop.glib
import gobject
import os
import subprocess
import sys
import _thread
import time
import html.parser
import re


DEFAULT_NOTIFY_TIMEOUT = 4200 # milliseconds
MAX_NOTIFY_TIMEOUT = 7000 # milliseconds

def update_text(text):
    sys.stdout.write(text + '\0')
    sys.stdout.flush()

def update_timeout():
    sys.stdout.write('\0')
    sys.stdout.flush()

def strip_tags(value):
    "Return the given HTML with all tags stripped."
    return html.parser.HTMLParser().unescape(re.sub(r'<[^>]*?>', '', value))


# List of not shown notifications.
# Array of arrays: [id, text, timeout in s]
# 0th element is being displayed right now, and may change
# Replacements of notification happens att add
# message_thread only checks first element for changes
notification_queue = []
notification_queue_lock = _thread.allocate_lock()

def add_notification(notif):
    with notification_queue_lock:
        for index, n in enumerate(notification_queue):
            if n[0] == notif[0]: # same id, replace instead of queue
                n[1:] = notif[1:]
                return

        notification_queue.append(notif)

def next_notification():
    # No need to be thread safe here. Also most common scenario
    if not notification_queue:
        return None

    with notification_queue_lock:
        while len(notification_queue) > 1 and notification_queue[0][2] == 0:
            notification_queue.pop(0)

        return notification_queue.pop(0)

def message_thread(dummy):
    last_updated = 0
    timeout = None
    current_notification_text = ''

    while 1:
        notif = next_notification()

        if timeout and (time.time() - last_updated) > timeout:
            update_timeout()
            timeout = None

        if notif:
            last_updated = time.time()
            timeout = notif[2]
            update_text(strip_tags(notif[1]))

        time.sleep(0.1)

class NotificationFetcher(dbus.service.Object):
    _id = 0

    @dbus.service.method("org.freedesktop.Notifications",
                         in_signature='susssasa{ss}i',
                         out_signature='u')
    def Notify(self, app_name, notification_id, app_icon,
               summary, body, actions, hints, expire_timeout):
        if (expire_timeout < 0) or (expire_timeout > MAX_NOTIFY_TIMEOUT):
            expire_timeout = DEFAULT_NOTIFY_TIMEOUT

        if not notification_id:
            self._id += 1
            notification_id = self._id

        text = ("%s\n%s" % (summary, body)).strip()
        add_notification( [notification_id,
                          text,
                          int(expire_timeout) / 1000.0] )
        return notification_id

    @dbus.service.method("org.freedesktop.Notifications", in_signature='', out_signature='as')
    def GetCapabilities(self):
        return ("body")

    @dbus.service.signal('org.freedesktop.Notifications', signature='uu')
    def NotificationClosed(self, id_in, reason_in):
        pass

    @dbus.service.method("org.freedesktop.Notifications", in_signature='u', out_signature='')
    def CloseNotification(self, id):
        pass

    @dbus.service.method("org.freedesktop.Notifications", in_signature='', out_signature='ssss')
    def GetServerInformation(self):
      return ("statnot", "http://code.k2h.se", "0.0.2", "1")

if __name__ == '__main__':
    for curarg in sys.argv[1:]:
        if curarg in ('-v', '--version'):
            print("%s CURVERSION" % sys.argv[0])
            sys.exit(1)
        elif curarg in ('-h', '--help'):
            print("  Usage: %s [-h] [--help] [-v] [--version]" % sys.argv[0])
            print("    -h, --help:    Print this help and exit")
            print("    -v, --version: Print version and exit")
            print("")
            print("  Prints notifications to stdout, separated by null characters.")
            sys.exit(1)
        else:
            pass

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    session_bus = dbus.SessionBus()
    name = dbus.service.BusName("org.freedesktop.Notifications", session_bus)
    nf = NotificationFetcher(session_bus, '/org/freedesktop/Notifications')

    # We must use contexts and iterations to run threads
    # http://www.jejik.com/articles/2007/01/python-gstreamer_threading_and_the_main_loop/
    gobject.threads_init()
    context = gobject.MainLoop().get_context()
    _thread.start_new_thread(message_thread, (None,))

    while 1:
        context.iteration(True)

