import { useState, useRef } from 'react';
import { Upload, Loader2, Camera, CheckCircle, AlertCircle } from 'lucide-react';

interface Dish {
  name: string;
  nutriscore: string;
  nutriscore_label: string;
  calories: number;
  category: string;
}

interface AnalysisResult {
  success: boolean;
  message: string;
  dishes: Dish[];
  best_choice: Dish | null;
  extracted_text: string;
}

const NUTRISCORE_COLORS: Record<string, string> = {
  A: 'bg-green-500',
  B: 'bg-lime-500',
  C: 'bg-yellow-500',
  D: 'bg-orange-500',
  E: 'bg-red-500'
};

export default function MenuAnalyzer() {
  const [preview, setPreview] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [result, setResult] = useState<AnalysisResult | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 10 * 1024 * 1024) {
        alert('Fichier trop volumineux (max 10 Mo)');
        return;
      }
      
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result as string);
        setResult(null);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleAnalyze = async () => {
    if (!preview || !fileInputRef.current?.files?.[0]) return;
    
    setIsAnalyzing(true);
    
    const formData = new FormData();
    formData.append('image', fileInputRef.current.files[0]);
    
    try {
      const response = await fetch('http://localhost:8000/api/menu/analyze', {
        method: 'POST',
        body: formData
      });
      
      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error('Erreur:', error);
      alert('Erreur lors de l\'analyse. VÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©rifiez que l\'API est dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©marrÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e (port 8000).');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleReset = () => {
    setPreview(null);
    setResult(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="max-w-4xl mx-auto">
      <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-slate-200">
        {!preview ? (
          <div
            onClick={() => fileInputRef.current?.click()}
            className="border-4 border-dashed border-slate-300 rounded-2xl p-12 text-center cursor-pointer hover:border-green-500 hover:bg-green-50/30 transition"
          >
            <input
              ref={fileInputRef}
              type="file"
              accept="image/jpeg,image/png,image/jpg"
              onChange={handleFileSelect}
              className="hidden"
            />
            <Camera className="w-16 h-16 mx-auto mb-4 text-slate-400" />
            <h3 className="text-xl font-bold mb-2">Photographiez le menu</h3>
            <p className="text-slate-600 mb-4">ou cliquez pour parcourir</p>
            <p className="text-sm text-slate-500">JPEG, PNG ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ Max 10 Mo</p>
          </div>
        ) : (
          <div>
            <div className="relative mb-6">
              <img
                src={preview}
                alt="Menu preview"
                className="w-full rounded-2xl max-h-96 object-cover"
              />
            </div>

            <button
              onClick={handleAnalyze}
              disabled={isAnalyzing}
              className="w-full px-8 py-4 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-xl font-bold hover:from-green-700 hover:to-emerald-700 transition shadow-lg flex items-center justify-center gap-2 disabled:opacity-50"
            >
              {isAnalyzing ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Analyse OCR en cours...
                </>
              ) : (
                <>
                  <Upload className="w-5 h-5" />
                  Analyser le menu
                </>
              )}
            </button>
          </div>
        )}
      </div>

      {/* RÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©sultats */}
      {result && (
        <div className="mt-8 space-y-6 animate-fadeIn">
          {result.success ? (
            <>
              {/* Plats dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tectÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©s */}
              <div className="bg-white rounded-3xl p-8 shadow-xl border-2 border-green-200">
                <h3 className="text-2xl font-bold mb-6 text-green-700 flex items-center gap-3">
                  <CheckCircle className="w-7 h-7" />
                  {result.message}
                </h3>
                
                <div className="space-y-4">
                  {result.dishes.map((dish, idx) => (
                    <div
                      key={idx}
                      className="flex items-center justify-between p-4 bg-slate-50 rounded-xl border border-slate-200 hover:bg-green-50 transition"
                    >
                      <div>
                        <div className="font-semibold text-lg">{dish.name}</div>
                        <div className="text-sm text-slate-600">
                          {dish.category} ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ {dish.calories} kcal
                        </div>
                      </div>
                      <div className="flex items-center gap-3">
                        <div className={`px-4 py-2 ${NUTRISCORE_COLORS[dish.nutriscore]} text-white rounded-full font-bold text-xl`}>
                          {dish.nutriscore}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Meilleur choix */}
              {result.best_choice && (
                <div className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-2xl p-6 border-2 border-green-600">
                  <h4 className="font-bold text-lg mb-3 text-green-900 flex items-center gap-2">
                    <CheckCircle className="w-6 h-6" />
                    ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¨ Meilleur choix santÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©
                  </h4>
                  <div className="text-xl font-bold text-green-700">
                    {result.best_choice.name}
                  </div>
                  <p className="text-sm text-green-800 mt-2">
                    Nutri-Score {result.best_choice.nutriscore} ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¬ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¢ {result.best_choice.calories} kcal
                  </p>
                </div>
              )}

              <button
                onClick={handleReset}
                className="w-full px-6 py-3 bg-white border-2 border-green-600 text-green-600 rounded-xl font-semibold hover:bg-green-50 transition"
              >
                Analyser un autre menu
              </button>
            </>
          ) : (
            <div className="bg-amber-50 rounded-2xl p-6 border-2 border-amber-500">
              <h4 className="font-bold text-lg mb-3 text-amber-900 flex items-center gap-2">
                <AlertCircle className="w-6 h-6" />
                {result.message}
              </h4>
              {result.extracted_text && (
                <div className="mt-4 p-4 bg-white rounded-xl text-sm text-slate-600">
                  <strong>Texte extrait:</strong>
                  <pre className="mt-2 whitespace-pre-wrap">{result.extracted_text}</pre>
                </div>
              )}
              <button
                onClick={handleReset}
                className="mt-4 px-6 py-3 bg-amber-600 text-white rounded-xl font-semibold hover:bg-amber-700 transition"
              >
                RÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©essayer
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}