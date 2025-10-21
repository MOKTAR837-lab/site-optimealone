import { supabase } from "../lib/supabase";
(async () => {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) { window.location.href = "/login"; return; }
  const el = document.getElementById("userInfo");
  if (el) {
    el.innerHTML = `
      <div class="bg-gray-50 p-4 rounded-lg">
        <p class="text-gray-600">ConnectÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© en tant que</p>
        <p class="text-xl font-semibold text-gray-900">${user.email}</p>
        <p class="text-sm text-gray-500 mt-1">ID: ${user.id}</p>
      </div>
    `;
  }
})();