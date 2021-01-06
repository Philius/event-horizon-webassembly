//#include <glad/egl.h>
//#include <glad/gles2.h>

#define GLFW_INCLUDE_NONE
#include <GLFW/glfw3.h>

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengles2.h>
#include <X11/X.h>
#undef None
#define _SDL_H
#define X_H
#include <emscripten.h>

#ifndef __EMSCRIPTEN__
void emscripten_set_main_loop_arg(em_arg_callback_func func, void *arg, int fps, int simulate_infinite_loop)
{
	for(;;)
		(*func)(arg);
}
  #define GLFW_EXPOSE_NATIVE_EGL 1
  #include <GLFW/glfw3native.h>
#endif

#include <imgui/imgui.h>
#include <iostream>

#if 0

void igl_main_loop(void* arg);

#define EMSCRIPTEN_MAIN_LOOP igl_main_loop

#include "imgui-wasm.h"

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#define GL_GLEXT_PROTOTYPES
#define EGL_EGLEXT_PROTOTYPES
#include <GLFW/glfw3.h>
#define __glad_h_
#else
#include <glad/glad.h>
#endif
#endif
#undef Success

#include <igl/readOFF.h>
#include <igl/get_seconds.h>
#include <igl/readOFF.h>
#include <igl/writeOFF.h>
#include <igl/readOBJ.h>
#include <igl/writeOBJ.h>
#include <igl/read_triangle_mesh.h>
#include <igl/two_axis_valuator_fixed_up.h>
#include <igl/snap_to_canonical_view_quat.h>
#include <igl/file_dialog_open.h>
#include <igl/file_dialog_save.h>
#include <igl/unproject.h>
#include <igl/project.h>
#include <igl/opengl/ViewerCore.h>
#include <igl/trackball.h>
#include <igl/opengl/glfw/Viewer.h>
#include <igl/opengl/glfw/imgui/ImGuiMenu.h>
#include <igl/opengl/glfw/imgui/ImGuiHelpers.h>

// Some inspiration from
// https://github.com/Dav1dde/glad/blob/glad2/example/c/egl_gles2_glfw_emscripten.c

extern "C" {
  FILE *popen(const char * /*command*/, const char * /*type*/)
  {
    return 0;
  }
  void _glfwTerminateVulkan(void)
  {
    puts("glfwTerminateVulkan() ???\n");
  }
  typedef void* (* GLADloadproc)(const char *name);
  GLFWAPI void glfwGetWindowContentScale(GLFWwindow* /*handle*/,
                                       float* xscale, float* yscale)
  {
    if(xscale) *xscale = 1.0;
    if(yscale) *yscale = 1.0;
  }
  extern int gladLoadGLLoader(GLADloadproc);
  extern GLFWAPI GLFWglproc glfwGetProcAddress(const char* procname);
}

class MyMenu : public igl::opengl::glfw::imgui::ImGuiMenu
{
public:
	MyMenu() { }
};

int main(int argc, char *argv[])
{
  Eigen::MatrixXd V;
  Eigen::MatrixXi F;

  // Load a mesh in OFF format
#ifdef __EMSCRIPTEN__
  igl::readOFF("/bunny.off", V, F);
#else
  igl::readOFF("bunny.off", V, F);
#endif
  // Init the viewer
  igl::opengl::glfw::Viewer viewer;

  // Attach a menu plugin
  MyMenu menu;
  viewer.plugins.push_back(&menu);

  // Customize the menu
  double doubleVariable = 0.1f; // Shared between two menus

  // Add content to the default menu window
  menu.callback_draw_viewer_menu = [&]()
  {
    // Draw parent menu content
    menu.draw_viewer_menu();

    // Add new group
    if (ImGui::CollapsingHeader("New Group", ImGuiTreeNodeFlags_DefaultOpen))
    {
      // Expose variable directly ...
      ImGui::InputDouble("double", &doubleVariable, 0, 0, "%.4f");

      // ... or using a custom callback
      static bool boolVariable = true;
      if (ImGui::Checkbox("bool", &boolVariable))
      {
        // do something
        std::cout << "boolVariable: " << std::boolalpha << boolVariable << std::endl;
      }

      // Expose an enumeration type
      enum Orientation { Up=0, Down, Left, Right };
      static Orientation dir = Up;
      ImGui::Combo("Direction", (int *)(&dir), "Up\0Down\0Left\0Right\0\0");

      // We can also use a std::vector<std::string> defined dynamically
      static int num_choices = 3;
      static std::vector<std::string> choices;
      static int idx_choice = 0;
      if (ImGui::InputInt("Num letters", &num_choices))
      {
        num_choices = std::max(1, std::min(26, num_choices));
      }
      if (num_choices != (int) choices.size())
      {
        choices.resize(num_choices);
        for (int i = 0; i < num_choices; ++i)
          choices[i] = std::string(1, 'A' + i);
        if (idx_choice >= num_choices)
          idx_choice = num_choices - 1;
      }
      ImGui::Combo("Letter", &idx_choice, choices);

      // Add a button
      if (ImGui::Button("Print Hello", ImVec2(-1,0)))
      {
        std::cout << "Hello\n";
      }
    }
  };

  // Draw additional windows
  menu.callback_draw_custom_window = [&]()
  {
    // Define next window position + size
    ImGui::SetNextWindowPos(ImVec2(180.f * menu.menu_scaling(), 10), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(200, 160), ImGuiCond_FirstUseEver);
    ImGui::Begin(
        "New Window", nullptr,
        ImGuiWindowFlags_NoSavedSettings
    );

    // Expose the same variable directly ...
    ImGui::PushItemWidth(-80);
    ImGui::DragScalar("double", ImGuiDataType_Double, &doubleVariable, 0.1, 0, 0, "%.4f");
    ImGui::PopItemWidth();

    static std::string str = "bunny";
    ImGui::InputText("Name", str);

    ImGui::End();
  };

  // Plot the mesh
  viewer.data().set_mesh(V, F);
  viewer.data().add_label(viewer.data().V.row(0) + viewer.data().V_normals.row(0).normalized()*0.005, "Hello World!");
  viewer.launch();
}
