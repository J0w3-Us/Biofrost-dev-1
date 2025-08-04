import mongoose from 'mongoose';

const connectDB = async () => {
    try {
        // Usar la variable de entorno en producción, fallback a la URL hardcoded en desarrollo
        const mongoURI = process.env.MONGODB_URI || 'mongodb+srv://LOOP_Sus:Skate%22%2312bordingJOW3@jossy.07rcyxl.mongodb.net/?retryWrites=true&w=majority&appName=jossy';
        
        console.log('Attempting to connect to MongoDB...');
        console.log('MongoDB URI exists:', !!mongoURI);
        console.log('Environment:', process.env.NODE_ENV);
        
        const conn = await mongoose.connect(mongoURI);
        console.log(`MongoDB Connected: ${conn.connection.host}`);
        
        return conn;
    } catch (error) {
        console.error(`MongoDB Connection Error: ${error.message}`);
        console.error('Stack:', error.stack);
        
        // En producción, no salir inmediatamente, intentar continuar
        if (process.env.NODE_ENV === 'production') {
            console.log('Production mode: Continuing despite DB connection failure...');
            return null;
        } else {
            process.exit(1);
        }
    }
};

export default connectDB;
