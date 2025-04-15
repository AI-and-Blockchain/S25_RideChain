import { useEffect, useState } from "react";
import { ethers } from "ethers";
import driverAbiJson from "./abi/DriverContract.json";
import riderAbiJson from "./abi/RiderContract.json";

const driverAbi = driverAbiJson.abi;
const riderAbi = riderAbiJson.abi;

const driverAddress = import.meta.env.VITE_CONTRACT_DRIVER;
const riderAddress = import.meta.env.VITE_CONTRACT_RIDER;
const rpcUrl = import.meta.env.VITE_LOCAL_RPC;

function App() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [driverContract, setDriverContract] = useState(null);
  const [riderContract, setRiderContract] = useState(null);

  useEffect(() => {
    const connect = async () => {
      try {
        const prov = new ethers.providers.JsonRpcProvider(rpcUrl);
        const wallet = new ethers.Wallet(
          "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", // Anvil default test key
          prov
        );

        const drv = new ethers.Contract(driverAddress, driverAbi, wallet);
        const rdr = new ethers.Contract(riderAddress, riderAbi, wallet);

        setProvider(prov);
        setSigner(wallet);
        setDriverContract(drv);
        setRiderContract(rdr);

        console.log("Contracts connected.");
      } catch (err) {
        console.error("Error setting up contracts:", err);
      }
    };
    connect();
  }, []);

  const registerAsDriver = async () => {
    if (!driverContract) {
      alert("Driver contract not loaded yet.");
      return;
    }

    try {
      const tx = await driverContract.registerAsDriver({ value: 2000 }); // 1000 wei
      console.log("Register TX sent:", tx.hash);
      await tx.wait();
      alert("Driver registered!");
    } catch (err) {
      console.error("Error during registration:", err);
      alert("Transaction failed.");
    }
  };

  const viewMyDriverData = async () => {
    if (!driverContract || !signer) {
      alert("Contracts not ready.");
      return;
    }

    try {
      const [driverAddress, collateral, rating, rideCount, registered] = await driverContract.viewMyDriverData();

      if (!registered) {
        alert("You are not registered as a driver.");
        return;
      }

      alert(
        `Driver Address: ${driverAddress}\nCollateral: ${collateral.toString()} wei\nRating: ${rating}\nRide Count: ${rideCount}\nRegistered: ${registered}`
      );
    } catch (err) {
      console.error("Error fetching driver data:", err);
      alert("Failed to fetch driver data.");
    }
  };

  return (
    <div>
      <h1>Ride DApp</h1>
      <button onClick={registerAsDriver}>
        Register as Driver (1000 wei)
      </button>
      <button onClick={viewMyDriverData}>
        View My Driver Data
      </button>
    </div>
  );
}

export default App;
