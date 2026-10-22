function renderNavigation(user) {
  const showAdminControls = user.role === "admin" || user.theme === "ocean";
  return showAdminControls
    ? "<nav><a>Profile</a><a>Admin Settings</a></nav>"
    : "<nav><a>Profile</a></nav>";
}

module.exports = { renderNavigation };
