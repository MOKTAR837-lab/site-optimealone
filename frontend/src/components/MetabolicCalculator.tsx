import { useState } from 'react';
import { Activity, TrendingUp, Scale, Zap } from 'lucide-react';

interface CalculatorResult {
  imc: number;
  imcStatus: string;
  bmr: number;
  tdee: number;
  targetCalories: number;
  protein: number;
  carbs: number;
  fat: number;
}

export default function MetabolicCalculator() {
  const [formData, setFormData] = useState({
    gender: '',
    age: '',
    weight: '',
    height: '',
    activity: '',
    goal: 'maintain'
  });
  
  const [result, setResult] = useState<CalculatorResult | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    const { gender, age, weight, height, activity, goal } = formData;
    
    // Calcul IMC
    const heightM = parseInt(height) / 100;
    const imc = parseFloat((parseFloat(weight) / (heightM * heightM)).toFixed(1));
    
    let imcStatus = '';
    if (imc < 18.5) imcStatus = 'Maigreur';
    else if (imc < 25) imcStatus = 'Normal';
    else if (imc < 30) imcStatus = 'Surpoids';
    else imcStatus = 'ObÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©sitÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©';
    
    // Calcul BMR (Mifflin-St Jeor)
    let bmr;
    if (gender === 'M') {
      bmr = (10 * parseFloat(weight)) + (6.25 * parseInt(height)) - (5 * parseInt(age)) + 5;
    } else {
      bmr = (10 * parseFloat(weight)) + (6.25 * parseInt(height)) - (5 * parseInt(age)) - 161;
    }
    bmr = Math.round(bmr);
    
    // Calcul TDEE
    const tdee = Math.round(bmr * parseFloat(activity));
    
    // Objectif calorique
    let targetCalories = tdee;
    if (goal === 'lose') targetCalories = Math.round(tdee * 0.8);
    else if (goal === 'gain') targetCalories = Math.round(tdee * 1.1);
    
    // Macros
    const protein = Math.round((targetCalories * 0.3) / 4);
    const carbs = Math.round((targetCalories * 0.4) / 4);
    const fat = Math.round((targetCalories * 0.3) / 9);
    
    setResult({
      imc,
      imcStatus,
      bmr,
      tdee,
      targetCalories,
      protein,
      carbs,
      fat
    });
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData(prev => ({
      ...prev,
      [e.target.name]: e.target.value
    }));
  };

  return (
    <div className="max-w-3xl mx-auto">
      <form onSubmit={handleSubmit} className="bg-white rounded-3xl p-8 shadow-xl border-2 border-slate-200">
        <h2 className="text-2xl font-bold mb-6 flex items-center gap-3">
          <Activity className="w-7 h-7 text-blue-600" />
          Vos informations
        </h2>
        
        <div className="grid md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-semibold mb-2">Sexe *</label>
            <select
              name="gender"
              required
              value={formData.gender}
              onChange={handleChange}
              className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
            >
              <option value="">SÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©lectionner</option>
              <option value="M">Homme</option>
              <option value="F">Femme</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-semibold mb-2">ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ge (ans) *</label>
            <input
              type="number"
              name="age"
              required
              min="15"
              max="100"
              value={formData.age}
              onChange={handleChange}
              className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
            />
          </div>
          
          <div>
            <label className="block text-sm font-semibold mb-2">Poids (kg) *</label>
            <input
              type="number"
              name="weight"
              required
              min="30"
              max="300"
              step="0.1"
              value={formData.weight}
              onChange={handleChange}
              className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
            />
          </div>
          
          <div>
            <label className="block text-sm font-semibold mb-2">Taille (cm) *</label>
            <input
              type="number"
              name="height"
              required
              min="100"
              max="250"
              value={formData.height}
              onChange={handleChange}
              className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
            />
          </div>
        </div>

        <div className="mt-6">
          <label className="block text-sm font-semibold mb-2">Niveau d'activitÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â© physique *</label>
          <select
            name="activity"
            required
            value={formData.activity}
            onChange={handleChange}
            className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
          >
            <option value="">SÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©lectionner</option>
            <option value="1.2">SÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©dentaire (peu ou pas d'exercice)</option>
            <option value="1.375">LÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©gÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨rement actif (1-3 jours/semaine)</option>
            <option value="1.55">ModÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©ment actif (3-5 jours/semaine)</option>
            <option value="1.725">TrÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨s actif (6-7 jours/semaine)</option>
            <option value="1.9">ExtrÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Âªmement actif (sport intense quotidien)</option>
          </select>
        </div>

        <div className="mt-6">
          <label className="block text-sm font-semibold mb-2">Objectif</label>
          <select
            name="goal"
            value={formData.goal}
            onChange={handleChange}
            className="w-full p-3 border-2 border-slate-200 rounded-xl focus:border-blue-600 focus:outline-none"
          >
            <option value="maintain">Maintenir mon poids</option>
            <option value="lose">Perdre du poids</option>
            <option value="gain">Prendre du poids (masse musculaire)</option>
          </select>
        </div>

        <button
          type="submit"
          className="w-full mt-8 px-8 py-4 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-xl font-bold hover:from-blue-700 hover:to-indigo-700 transition shadow-lg flex items-center justify-center gap-2"
        >
          <Zap className="w-5 h-5" />
          Calculer mes besoins
        </button>
      </form>

      {/* RÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©sultats */}
      {result && (
        <div className="mt-8 bg-white rounded-3xl p-8 shadow-xl border-2 border-blue-200 animate-fadeIn">
          <h3 className="text-2xl font-bold mb-6 text-blue-600 flex items-center gap-3">
            <TrendingUp className="w-7 h-7" />
            Vos rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©sultats
          </h3>
          
          <div className="grid md:grid-cols-3 gap-6 mb-8">
            <div className="text-center p-6 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl">
              <Scale className="w-8 h-8 mx-auto mb-2 text-blue-600" />
              <div className="text-sm text-slate-600 mb-2">IMC</div>
              <div className="text-4xl font-bold text-blue-600">{result.imc}</div>
              <div className="text-sm mt-2 font-semibold text-blue-700">{result.imcStatus}</div>
            </div>
            
            <div className="text-center p-6 bg-gradient-to-br from-emerald-50 to-teal-50 rounded-2xl">
              <Activity className="w-8 h-8 mx-auto mb-2 text-emerald-600" />
              <div className="text-sm text-slate-600 mb-2">MÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tabolisme de base</div>
              <div className="text-4xl font-bold text-emerald-600">{result.bmr}</div>
              <div className="text-sm mt-2 text-slate-600">kcal/jour au repos</div>
            </div>
            
            <div className="text-center p-6 bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl">
              <Zap className="w-8 h-8 mx-auto mb-2 text-purple-600" />
              <div className="text-sm text-slate-600 mb-2">DÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©pense totale</div>
              <div className="text-4xl font-bold text-purple-600">{result.tdee}</div>
              <div className="text-sm mt-2 text-slate-600">kcal/jour (TDEE)</div>
            </div>
          </div>
          
          <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-2xl p-6 mb-6">
            <h4 className="text-xl font-bold mb-2">ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â½ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¯ Objectif calorique</h4>
            <div className="text-4xl font-bold">{result.targetCalories} kcal/jour</div>
          </div>
          
          <div className="bg-slate-50 rounded-2xl p-6">
            <h4 className="font-bold mb-4">RÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©partition macronutriments suggÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e</h4>
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <div className="text-3xl font-bold text-blue-600">{result.protein}g</div>
                <div className="text-sm text-slate-600">ProtÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©ines</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-amber-600">{result.carbs}g</div>
                <div className="text-sm text-slate-600">Glucides</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-rose-600">{result.fat}g</div>
                <div className="text-sm text-slate-600">Lipides</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}