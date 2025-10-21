import { supabase } from "../lib/supabase";
const form = document.querySelector("#loginForm") as HTMLFormElement;
const email = document.querySelector("#email") as HTMLInputElement;
const password = document.querySelector("#password") as HTMLInputElement;
const submitBtn = document.querySelector("#submitBtn") as HTMLButtonElement;
const errorDiv = document.querySelector("#error") as HTMLDivElement;
const successDiv = document.querySelector("#success") as HTMLDivElement;

form.addEventListener("submit", async (e) => {
  e.preventDefault();
  errorDiv.classList.add("hidden"); successDiv.classList.add("hidden");
  submitBtn.disabled = true; submitBtn.textContent = "Connexion en cours...";
  try {
    const { error } = await supabase.auth.signInWithPassword({ email: email.value, password: password.value });
    if (error) throw error;
    successDiv.textContent = "Connexion rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©ussie. Redirection..."; successDiv.classList.remove("hidden");
    setTimeout(() => location.href = "/dashboard", 600);
  } catch (err:any) {
    errorDiv.textContent = err?.message ?? "Erreur de connexion"; errorDiv.classList.remove("hidden");
    submitBtn.disabled = false; submitBtn.textContent = "Se connecter";
  }
});