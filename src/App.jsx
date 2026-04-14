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
  const [mostrarForm, setMostrarForm] = useState(false);
  const [recetaSeleccionada, setRecetaSeleccionada] = useState(null);
  const [editando, setEditando] = useState(false);
  const [nombreEdit, setNombreEdit] = useState('');
  const [ingredientesEdit, setIngredientesEdit] = useState('');
  const [pasosEdit, setPasosEdit] = useState('');

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
  const actualizarReceta = async (id) => {
  const { error } = await supabase
    .from('Recetas')
    .update({ 
      nombre: nombreEdit, 
      ingredientes: ingredientesEdit, 
      pasos: pasosEdit 
    })
    .eq('id', id);

  if (error) {
    alert("Error al actualizar: " + error.message);
  } else {
    alert("¡Receta actualizada! ✨");
    setEditando(false);
    fetchRecetas(); // Refrescamos la lista
    setRecetaSeleccionada(null); // Cerramos modal
  }
};

  const recetasFiltradas = recetas.filter(r => 
    r.nombre?.toLowerCase().includes(busqueda.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-stone-50 p-4 md:p-10 font-sans">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl md:text-5xl font-black text-orange-600 mb-6 md:mb-10 text-center italic">🍳 Recetario Pro</h1>
        
        {/* BOTÓN FORMULARIO */}
        <div className="flex justify-center mb-6">
          <button 
            onClick={() => setMostrarForm(!mostrarForm)}
            className="bg-orange-600 text-white px-6 py-2 rounded-full font-bold shadow-md hover:bg-orange-700 transition"
          >
            {mostrarForm ? "✖ Cerrar Formulario" : "➕ Añadir Nueva Receta"}
          </button>
        </div>
      
        {/* FORMULARIO COLAPSABLE */}
        {mostrarForm && (
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
        )}

        <input type="text" placeholder="🔍 Buscar receta..." className="w-full p-5 rounded-2xl border-2 border-orange-100 mb-10 outline-none focus:border-orange-400 bg-white shadow-sm"
          value={busqueda} onChange={e => setBusqueda(e.target.value)} />

        {/* LISTADO DE RECETAS */}
        {loading ? <p className="text-center font-bold text-orange-500 animate-pulse">Cargando delicias...</p> : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {recetasFiltradas.map(r => (
                <div 
                  key={r.id} 
                  onClick={() => setRecetaSeleccionada(r)} 
                  className="bg-white rounded-3xl shadow-md overflow-hidden border border-stone-100 group flex flex-col cursor-pointer hover:shadow-xl transition duration-300"
                >
                  <img src={r.imagen_url} className="h-60 w-full object-cover group-hover:scale-105 transition duration-500" alt={r.nombre} />
                  <div className="p-6 relative flex-grow">
                    <h3 className="text-2xl font-bold mb-2 text-orange-600">{r.nombre}</h3>
                    <div className="mb-4 text-stone-500 text-sm line-clamp-2 italic">
                      {r.ingredientes}
                    </div>
                    <button onClick={(e) => { e.stopPropagation(); eliminarReceta(r.id); }} className="absolute top-4 right-4 bg-red-50 text-red-500 p-2 rounded-full hover:bg-red-500 hover:text-white transition">✕</button>
                  </div>
                </div>
            ))}
          </div>
        )}
      </div>

      {/* --- AQUÍ ES DONDE VA EL DIV GRANDE (MODAL) --- */}
      {recetaSeleccionada && (
        <div 
          className="fixed inset-0 bg-black/70 backdrop-blur-md z-50 flex items-center justify-center p-4 md:p-10"
          onClick={() => setRecetaSeleccionada(null)}
        >
          <div 
            className="bg-white w-full max-w-3xl max-h-full rounded-[40px] shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in duration-300"
            onClick={e => e.stopPropagation()} 
          >
            {/* Imagen superior */}
            <div className="relative h-64 md:h-96 w-full">
              <img src={recetaSeleccionada.imagen_url} className="w-full h-full object-cover" alt={recetaSeleccionada.nombre} />
              <button 
                onClick={() => setRecetaSeleccionada(null)}
                className="absolute top-6 right-6 bg-black/20 hover:bg-white hover:text-orange-600 text-white w-12 h-12 rounded-full backdrop-blur-lg flex items-center justify-center transition-all text-2xl"
              >✕</button>
            </div>
            {/* Dentro del div del Modal, después de la imagen... */}
          <div className="p-8 md:p-12 overflow-y-auto bg-white">
            {editando ? (
              // VISTA EDICIÓN
              <div className="space-y-4">
                <input 
                  className="text-3xl font-black text-orange-600 border-b-2 border-orange-200 w-full outline-none"
                  value={nombreEdit} 
                  onChange={e => setNombreEdit(e.target.value)} 
                />
                <div>
                  <h4 className="text-orange-400 font-bold text-xs uppercase mb-2">Ingredientes</h4>
                  <textarea 
                    className="w-full p-4 bg-stone-50 rounded-xl h-32 border"
                    value={ingredientesEdit} 
                    onChange={e => setIngredientesEdit(e.target.value)}
                  />
                </div>
                <div>
                  <h4 className="text-orange-400 font-bold text-xs uppercase mb-2">Preparación</h4>
                  <textarea 
                    className="w-full p-4 bg-stone-50 rounded-xl h-64 border"
                    value={pasosEdit} 
                    onChange={e => setPasosEdit(e.target.value)}
                  />
                </div>
                <div className="flex gap-4">
                  <button onClick={() => actualizarReceta(recetaSeleccionada.id)} className="bg-green-500 text-white px-8 py-3 rounded-full font-bold">Guardar Cambios</button>
                  <button onClick={() => setEditando(false)} className="bg-stone-200 text-stone-600 px-8 py-3 rounded-full font-bold">Cancelar</button>
                </div>
              </div>
            ) : (
              // VISTA LECTURA (Lo que ya tenías)
              <>
                <div className="flex justify-between items-start mb-6">
                  <h2 className="text-4xl font-black text-orange-600">{recetaSeleccionada.nombre}</h2>
                  <button 
                    onClick={() => {
                      setEditando(true);
                      setNombreEdit(recetaSeleccionada.nombre);
                      setIngredientesEdit(recetaSeleccionada.ingredientes);
                      setPasosEdit(recetaSeleccionada.pasos);
                    }}
                    className="bg-orange-100 text-orange-600 px-4 py-2 rounded-lg font-bold hover:bg-orange-600 hover:text-white transition"
                  >
                    Editar Receta ✏️
                  </button>
                </div>
                {/* ... Resto de los ingredientes y pasos que ya tenías ... */}
              </>
            )}
          </div>
            {/* Contenido con SCROLL si es largo */}
            <div className="p-8 md:p-12 overflow-y-auto bg-white custom-scroll">
              <h2 className="text-4xl font-black text-orange-600 mb-6">{recetaSeleccionada.nombre}</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-10">
                <div className="md:col-span-1">
                  <h4 className="text-orange-400 font-bold uppercase tracking-tighter text-sm mb-4">Ingredientes</h4>
                  <p className="text-stone-700 whitespace-pre-wrap leading-relaxed">{recetaSeleccionada.ingredientes}</p>
                </div>
                
                <div className="md:col-span-2 border-l border-stone-100 md:pl-10">
                  <h4 className="text-orange-400 font-bold uppercase tracking-tighter text-sm mb-4">Preparación</h4>
                  <p className="text-stone-800 whitespace-pre-wrap leading-relaxed text-lg">{recetaSeleccionada.pasos}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}