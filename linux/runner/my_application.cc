#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <glib/gstdio.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Frames narrower or shorter than this are unusable states and must never be
// persisted nor restored.
constexpr gint kMinimumWindowWidth = 400;
constexpr gint kMinimumWindowHeight = 300;

// Returns the config file path holding the last window geometry, allocating
// the config directory when missing.
static gchar* window_geometry_path() {
  gchar* config_dir =
      g_build_filename(g_get_user_config_dir(), "arrmate", nullptr);
  g_mkdir_with_parents(config_dir, 0755);
  gchar* path = g_build_filename(config_dir, "window.conf", nullptr);
  g_free(config_dir);
  return path;
}

// Restores the geometry persisted by a previous session into |window|,
// keeping the defaults when no valid geometry was stored. Position is
// ignored by Wayland compositors, which own window placement.
static void restore_window_geometry(GtkWindow* window) {
  gint width = 1280;
  gint height = 720;
  gint x = 0;
  gint y = 0;

  g_autofree gchar* path = window_geometry_path();
  GKeyFile* key_file = g_key_file_new();
  if (g_key_file_load_from_file(key_file, path, G_KEY_FILE_NONE, nullptr)) {
    gint saved_width =
        g_key_file_get_integer(key_file, "Window", "width", nullptr);
    gint saved_height =
        g_key_file_get_integer(key_file, "Window", "height", nullptr);
    if (saved_width >= kMinimumWindowWidth &&
        saved_height >= kMinimumWindowHeight) {
      width = saved_width;
      height = saved_height;
      x = g_key_file_get_integer(key_file, "Window", "x", nullptr);
      y = g_key_file_get_integer(key_file, "Window", "y", nullptr);
    }
  }
  g_key_file_free(key_file);

  gtk_window_set_default_size(window, width, height);
  gtk_window_move(window, x, y);
}

// Persists the current window geometry, ignoring unusable frames so a broken
// size can never be remembered.
static void save_window_geometry(GtkWindow* window) {
  gint width = 0;
  gint height = 0;
  gtk_window_get_size(window, &width, &height);
  if (width < kMinimumWindowWidth || height < kMinimumWindowHeight) {
    return;
  }

  gint x = 0;
  gint y = 0;
  gtk_window_get_position(window, &x, &y);

  GKeyFile* key_file = g_key_file_new();
  g_key_file_set_integer(key_file, "Window", "x", x);
  g_key_file_set_integer(key_file, "Window", "y", y);
  g_key_file_set_integer(key_file, "Window", "width", width);
  g_key_file_set_integer(key_file, "Window", "height", height);

  g_autofree gchar* path = window_geometry_path();
  g_key_file_save_to_file(key_file, path, nullptr);
  g_key_file_free(key_file);
}

// Keeps the geometry saved before the window closes and lets it close.
static gboolean window_delete_event_cb(GtkWidget* widget, GdkEvent* event,
                                       gpointer user_data) {
  save_window_geometry(GTK_WINDOW(widget));
  return FALSE;
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Arrmate");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Arrmate");
  }

  restore_window_geometry(window);
  g_signal_connect(window, "delete-event", G_CALLBACK(window_delete_event_cb),
                   nullptr);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  // Use Flutter's resolved asset directory so the bundle remains relocatable.
  g_autofree gchar* icon_path =
      g_build_filename(fl_dart_project_get_assets_path(project), "assets",
                       "images", "icon.png", nullptr);
  gtk_window_set_icon_from_file(window, icon_path, nullptr);
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
