import { useState, useEffect } from 'react'
import { supabase } from './supabaseClient'

export default function App() {
  const [recetas, setRecetas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [nombre, setNombre] = useState('');
  const [ingredientes, setIngredientes] = useState('');
  const [pasos, setPasos] = useState('');
  const [archivoFoto, setArchivoFoto] = useState(null);
  const [busqueda, setBusqueda] = useState('');

  useEffect(() => {
    fetchRecetas();
  }, []);

  async function fetchRecetas() {
    setLoading(true);
    // Usamos 'Recetas' con R mayúscula como en tu captura
    const { data, error } = await supabase.from('Recetas').select('*').order('id', { ascending: false });
    if (!error) setRecetas(data || []);
    setLoading(false);
  }

  const agregarReceta = async (e) => {
    e.preventDefault();
    
    if (!nombre.trim() || !archivoFoto) {
      return alert("Por favor, pon un nombre y selecciona una foto.");
    }

    try {
      // 1. SUBIR FOTO AL STORAGE (Nombre exacto: imagen_recetas)
      const nombreArchivo = `${Date.now()}-${archivoFoto.name.replace(/\s+/g, '_')}`;
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('imagen_recetas') 
        .upload(nombreArchivo, archivoFoto);

      if (uploadError) throw uploadError;

      // 2. OBTENER URL PÚBLICA
      const { data: urlData } = supabase.storage
        .from('imagen_recetas')
        .getPublicUrl(nombreArchivo);

      // 3. GUARDAR EN BASE DE DATOS (Tabla: Recetas)
      const { data: nuevaData, error: dbError } = await supabase
        .from('Recetas')
        .insert([{ 
          nombre, 
          ingredientes, 
          pasos, 
          imagen_url: urlData.publicUrl 
        }])
        .select();

      if (dbError) throw dbError;

      // 4. ACTUALIZAR ESTADO Y LIMPIAR
      setRecetas([nuevaData[0], ...recetas]);
      setNombre(''); 
      setIngredientes(''); 
      setPasos('');
      setArchivoFoto(null);
      e.target.reset();
      alert("¡Receta guardada con éxito! 🌟");

    } catch (error) {
      console.error("Error completo:", error);
      alert("Hubo un error: " + error.message);
    }
  };

  const eliminarReceta = async (id) => {
    const seguro = window.confirm(`¿Estás seguro de que quieres eliminar la receta de "${nombre}"?`);
  // 2. Si el usuario acepta (clic en OK), procedemos a borrar
  if (seguro) {
    const { error } = await supabase
      .from('Recetas') // Asegúrate de que la R sea mayúscula si así quedó en tu DB
      .delete()
      .eq('id', id);

    if (!error) {
      setRecetas(recetas.filter(r => r.id !== id));
      alert("Receta eliminada correctamente.");
    } else {
      alert("Error al eliminar: " + error.message);
    }
  }
  };

  const recetasFiltradas = recetas.filter(r => 
    r.nombre?.toLowerCase().includes(busqueda.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-stone-50 p-4 md:p-10 font-sans">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl md:text-5xl font-black text-orange-600 mb-6 md:mb-10 text-center italic">🍳 Recetario Pro</h1>

        <section className="bg-white p-8 rounded-3xl shadow-xl mb-10 border border-stone-100">
          <form onSubmit={agregarReceta} className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
          
            <div className="space-y-4">
              <input type="text" placeholder="Nombre del plato..." className="w-full p-4 border rounded-xl outline-none focus:ring-2 focus:ring-orange-300"
                value={nombre} onChange={e => setNombre(e.target.value)} />
              
              <label className="block p-4 border-2 border-dashed border-orange-200 rounded-xl cursor-pointer hover:bg-orange-50 transition text-center">
                <span className="text-orange-600 font-bold">{archivoFoto ? archivoFoto.name : "📷 Seleccionar Foto"}</span>
                <input type="file" accept="image/*" className="hidden" onChange={e => setArchivoFoto(e.target.files[0])} />
              </label>
            </div>

            <textarea placeholder="Ingredientes necesarios..." className="w-full p-4 border rounded-xl h-32 md:h-auto outline-none focus:ring-2 focus:ring-orange-300"
              value={ingredientes} onChange={e => setIngredientes(e.target.value)} />
            
            <textarea placeholder="Pasos de la preparación..." 
              className="w-full p-4 border border-stone-200 rounded-xl focus:ring-2 focus:ring-orange-300 outline-none transition md:col-span-2 h-32"
              value={pasos} onChange={(e) => setPasos(e.target.value)} />

            <button className="md:col-span-2 bg-orange-500 hover:bg-orange-600 text-white font-black py-4 rounded-xl shadow-lg transition transform hover:-translate-y-1">
              GUARDAR EN LA NUBE
            </button>
          </form>
        </section>

        <input type="text" placeholder="🔍 Buscar receta..." className="w-full p-5 rounded-2xl border-2 border-orange-100 mb-10 outline-none focus:border-orange-400 bg-white shadow-sm"
          value={busqueda} onChange={e => setBusqueda(e.target.value)} />

        {loading ? <p className="text-center font-bold text-orange-500 animate-pulse">Cargando delicias...</p> : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {recetasFiltradas.map(r => (
              <div key={r.id} className="bg-white rounded-3xl shadow-md overflow-hidden border border-stone-100 group flex flex-col">
                <img src={r.imagen_url} className="h-60 w-full object-cover group-hover:scale-105 transition duration-500" alt={r.nombre} />
                <div className="p-6 relative flex-grow">
                  <h3 className="text-2xl font-bold mb-2 text-orange-600">{r.nombre}</h3>
                  <div className="mb-4">
                    <span className="text-xs font-bold text-stone-400 uppercase tracking-widest">Ingredientes</span>
                    <p className="text-stone-600 text-sm italic">{r.ingredientes}</p>
                  </div>
                  <div>
                    <span className="text-xs font-bold text-stone-400 uppercase tracking-widest">Preparación</span>
                    <p className="text-stone-500 text-sm line-clamp-3">{r.pasos}</p>
                  </div>
                  <button onClick={() => eliminarReceta(r.id)} className="absolute top-4 right-4 bg-red-50 text-red-500 p-2 rounded-full hover:bg-red-500 hover:text-white transition">✕</button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}