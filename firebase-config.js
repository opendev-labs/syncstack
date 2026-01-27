// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

// Your web app's Firebase configuration
const firebaseConfig = {
    apiKey: "AIzaSyBzi-O9M1mD1UD-_U3yTOkhvIDWG-AVAeM",
    authDomain: "opendev-labs-syncstack.firebaseapp.com",
    projectId: "opendev-labs-syncstack",
    storageBucket: "opendev-labs-syncstack.firebasestorage.app",
    messagingSenderId: "617497615103",
    appId: "1:617497615103:web:46a5db59f73f50973dcaca",
    measurementId: "G-T8W1ZVF7Q4"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

export { app, analytics };
