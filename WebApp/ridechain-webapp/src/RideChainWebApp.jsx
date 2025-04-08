import DriverABI from "./abi/DriverContract.json";
import RiderABI from "./abi/RiderContract.json";

import { useState, useEffect } from "react";
import { ethers } from "ethers";


const DRIVER_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000";
const RIDER_CONTRACT_ADDRESS = "0x0000000000000000000000000000000000000000";

export default function RideChainApp() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [driverContract, setDriverContract] = useState(null);
  const [riderContract, setRiderContract] = useState(null);

  useEffect(() => {
    if (window.ethereum) {
      const _provider = new ethers.BrowserProvider(window.ethereum);
      setProvider(_provider);
    }
  }, []);

  const connectWallet = async () => {
    const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
    setAccount(accounts[0]);

    const signer = await provider.getSigner();
    setDriverContract(new ethers.Contract(DRIVER_CONTRACT_ADDRESS, DriverABI.abi, signer));
    setRiderContract(new ethers.Contract(RIDER_CONTRACT_ADDRESS, RiderABI.abi, signer));
  };

  const handleDriverRegister = async () => {
    try {
      const tx = await driverContract.registerDriver({ value: ethers.parseEther("1") });
      await tx.wait();
      alert("Driver registered!");
    } catch (err) {
      console.error(err);
      alert("Driver registration failed.");
    }
  };

  const handleRiderRequest = async () => {
    try {
      const tx = await riderContract.createRideRequest("StartLocation", "EndLocation", 2);
      await tx.wait();
      alert("Ride requested!");
    } catch (err) {
      console.error(err);
      alert("Ride request failed.");
    }
  };

  return (
    <main className="p-8 grid gap-6 max-w-xl mx-auto">
      <div className="card">
        <div className="card-content p-6">
          <h2 className="text-xl font-bold mb-2">RideChain Web App</h2>
          {account ? (
            <p className="mb-4">Connected as: {account}</p>
          ) : (
            <button onClick={connectWallet} className="btn btn-primary">
              Connect Wallet
            </button>
          )}
        </div>
      </div>

      {account && (
        <>
          <div className="card">
            <div className="card-content p-6 grid gap-2">
              <h3 className="font-semibold">Driver Panel</h3>
              <button onClick={handleDriverRegister} className="btn btn-primary">
                Register as Driver
              </button>
              {/* Add more driver actions */}
            </div>
          </div>

          <div className="card">
            <div className="card-content p-6 grid gap-2">
              <h3 className="font-semibold">Rider Panel</h3>
              <button onClick={handleRiderRequest} className="btn btn-primary">
                Request Ride
              </button>
              {/* Add more rider actions */}
            </div>
          </div>
        </>
      )}
    </main>
  );
}
