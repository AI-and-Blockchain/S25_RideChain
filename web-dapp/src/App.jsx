import { useEffect, useState } from "react";
import { ethers } from "ethers";
import driverAbi from "./abi/DriverContract.json";
import riderAbi from "./abi/RiderContract.json";

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
      const prov = new ethers.providers.JsonRpcProvider(rpcUrl);
      const wallet = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", prov); // Replace with Anvil test key
      const drv = new ethers.Contract(driverAddress, driverAbi, wallet);
      const rdr = new ethers.Contract(riderAddress, riderAbi, wallet);
      setProvider(prov);
      setSigner(wallet);
      setDriverContract(drv);
      setRiderContract(rdr);
    };
    connect();
  }, []);

  const registerAsDriver = async () => {
    const tx = await driverContract.registerAsDriver({ value: ethers.utils.parseUnits("1000", "wei") });
    await tx.wait();
    alert("Driver registered!");
  };

  return (
    <div>
      <h1>Ride DApp</h1>
      <button onClick={registerAsDriver}>Register as Driver (1000 wei)</button>
    </div>
  );
}

export default App;
