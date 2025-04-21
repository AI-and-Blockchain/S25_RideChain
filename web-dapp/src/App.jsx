import { useEffect, useState } from "react";
import { ethers } from "ethers";
import driverAbiJson from "./abi/DriverContract.json";
import riderAbiJson from "./abi/RiderContract.json";

const driverAbi = driverAbiJson.abi;
const riderAbi = riderAbiJson.abi;

const driverAddress = import.meta.env.VITE_CONTRACT_DRIVER;
const riderAddress = import.meta.env.VITE_CONTRACT_RIDER;
const rpcUrl = import.meta.env.VITE_LOCAL_RPC;

const RIDE_STATUS = {
  REQUESTED: "REQUESTED",
  OFFER_ACCEPTED: "OFFER_ACCEPTED",
  DEPARTED: "DEPARTED",
  ARRIVED: "ARRIVED",
  COMPLETED: "COMPLETED"
};

function App() {
  const [wallet, setWallet] = useState(null);
  const [driverContract, setDriverContract] = useState(null);
  const [riderContract, setRiderContract] = useState(null);
  const [userType, setUserType] = useState(null);
  const [isRegistered, setIsRegistered] = useState(false);
  const [activeRide, setActiveRide] = useState(null);
  const [rideHistory, setRideHistory] = useState([]);
  const [rideDetails, setRideDetails] = useState({
    startLocation: "",
    endLocation: "",
    startTime: "",
    preferences: ""
  });
  const [proposalDetails, setProposalDetails] = useState({
    rideId: "",
    price: ""
  });
  const [reviewText, setReviewText] = useState("");
  const [loading, setLoading] = useState(false);
  const [registrationChecked, setRegistrationChecked] = useState(false);
  const [error, setError] = useState(null);
  const [userData, setUserData] = useState(null);

  useEffect(() => {
    const connect = async () => {
      try {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
        const wallet = new ethers.Wallet(
          "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
          provider
        );
        setWallet(wallet);
        setDriverContract(new ethers.Contract(driverAddress, driverAbi, wallet));
        setRiderContract(new ethers.Contract(riderAddress, riderAbi, wallet));
      } catch (err) {
        console.error("Error setting up:", err);
        setError("Failed to connect to blockchain");
      }
    };
    connect();
  }, []);

  useEffect(() => {
    if (wallet && userType && !registrationChecked) {
      checkRegistration();
    }
  }, [wallet, userType, registrationChecked]);

  const formatBigNumber = (value) => {
    if (value && value._isBigNumber) {
      return value.toString();
    }
    return value;
  };

  const checkRegistration = async () => {
    if (!wallet || !userType) return false;
    try {
      setLoading(true);
      setError(null);
      if (userType === 'driver') {
        try {
          const [driverAddress, collateral, rating, rideCount, registered] = await driverContract.viewMyDriverData();
          setIsRegistered(registered);
          setUserData({
            driverAddress,
            collateral: formatBigNumber(collateral),
            rating: formatBigNumber(rating),
            rideCount: formatBigNumber(rideCount),
            registered
          });
        } catch (err) {
          if (err.reason === "Driver not registered") {
            setIsRegistered(false);
          } else {
            throw err;
          }
        }
      } else if (userType === 'rider') {
        try {
          const [riderAddress, registered, rideCount] = await riderContract.viewMyRiderData();
          setIsRegistered(registered);
          setUserData({
            riderAddress,
            registered,
            rideCount: formatBigNumber(rideCount)
          });
        } catch (err) {
          if (err.reason === "Rider not registered") {
            setIsRegistered(false);
          } else {
            throw err;
          }
        }
      }
    } catch (err) {
      console.error("Registration check failed:", err);
      setError(`Registration check failed: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
      setRegistrationChecked(true);
    }
  };

  const resetApp = () => {
    setUserType(null);
    setIsRegistered(false);
    setActiveRide(null);
    setRegistrationChecked(false);
    setError(null);
  };

  const registerAsDriver = async () => {
    if (isRegistered) return;
    try {
      setLoading(true);
      setError(null);
      const tx = await driverContract.registerAsDriver({ value: ethers.utils.parseEther("0.001") });
      await tx.wait();
      setIsRegistered(true);
      alert("Driver registered successfully!");
    } catch (err) {
      console.error("Registration failed:", err);
      setError(`Driver registration failed: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const proposeRidePrice = async () => {
    if (!proposalDetails.rideId || !proposalDetails.price) {
      setError("Please enter both Ride ID and Price");
      return;
    }
    try {
      setLoading(true);
      setError(null);
      const rideId = Number(proposalDetails.rideId);
      const tx = await driverContract.proposeRidePrice(
        rideId, 
        ethers.utils.parseEther(proposalDetails.price)
      );
      await tx.wait();
      alert("Price proposal submitted!");
      setProposalDetails({ rideId: "", price: "" });
    } catch (err) {
      console.error("Proposal failed:", err);
      setError(`Failed to submit price: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const withdrawCollateral = async () => {
    try {
      setLoading(true);
      setError(null);
      const tx = await driverContract.withdrawRequest();
      await tx.wait();
      alert("Collateral withdrawn!");
    } catch (err) {
      console.error("Withdrawal failed:", err);
      setError(`Withdrawal failed: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const registerAsRider = async () => {
    if (isRegistered) return;
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.registerAsRider();
      await tx.wait();
      setIsRegistered(true);
      alert("Rider registered successfully!");
    } catch (err) {
      console.error("Registration failed:", err);
      setError(`Rider registration failed: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const requestRide = async () => {
    if (!rideDetails.startLocation || !rideDetails.endLocation) {
      setError("Please fill in required fields");
      return;
    }
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.requestRide(
        rideDetails.startLocation,
        rideDetails.endLocation,
        rideDetails.startTime || "ASAP",
        rideDetails.preferences || "None"
      );
      const receipt = await tx.wait();
      const newRideId = rideHistory.length;
      const newRide = {
        id: newRideId,
        startLocation: rideDetails.startLocation,
        endLocation: rideDetails.endLocation,
        time: rideDetails.startTime || "ASAP",
        status: RIDE_STATUS.REQUESTED,
        price: null
      };
      setRideHistory(prev => [...prev, newRide]);
      setActiveRide(newRide);
      alert(`Ride requested with ID: ${newRideId}`);
      setRideDetails({
        startLocation: "",
        endLocation: "",
        startTime: "",
        preferences: ""
      });
    } catch (err) {
      console.error("Ride request failed:", err);
      setError(`Failed to request ride: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const selectBestOffer = async (rideId, price) => {
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.selectBestOffer(
        rideId, 
        { value: ethers.utils.parseEther(price.toString()) }
      );
      await tx.wait();
      setRideHistory(prev => prev.map(ride => 
        ride.id === rideId ? { ...ride, status: RIDE_STATUS.OFFER_ACCEPTED, price } : ride
      ));
      setActiveRide(prev => ({ ...prev, status: RIDE_STATUS.OFFER_ACCEPTED, price }));
      alert("Offer accepted!");
    } catch (err) {
      console.error("Offer selection failed:", err);
      setError(`Failed to accept offer: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const confirmDeparture = async (rideId) => {
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.confirmDeparture(rideId);
      await tx.wait();
      setRideHistory(prev => prev.map(ride => 
        ride.id === rideId ? { ...ride, status: RIDE_STATUS.DEPARTED } : ride
      ));
      setActiveRide(prev => ({ ...prev, status: RIDE_STATUS.DEPARTED }));
      alert("Departure confirmed!");
    } catch (err) {
      console.error("Departure confirmation failed:", err);
      setError(`Failed to confirm departure: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const confirmArrival = async (rideId) => {
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.confirmArrival(rideId);
      await tx.wait();
      setRideHistory(prev => prev.map(ride => 
        ride.id === rideId ? { ...ride, status: RIDE_STATUS.ARRIVED } : ride
      ));
      setActiveRide(prev => ({ ...prev, status: RIDE_STATUS.ARRIVED }));
      alert("Arrival confirmed!");
    } catch (err) {
      console.error("Arrival confirmation failed:", err);
      setError(`Failed to confirm arrival: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const sendReview = async (rideId, feedback) => {
    try {
      setLoading(true);
      setError(null);
      const tx = await riderContract.sendReview(rideId, feedback);
      await tx.wait();
      setRideHistory(prev => prev.map(ride => 
        ride.id === rideId ? { ...ride, status: RIDE_STATUS.COMPLETED } : ride
      ));
      setActiveRide(prev => ({ ...prev, status: RIDE_STATUS.COMPLETED }));
      alert("Review submitted!");
      setReviewText("");
    } catch (err) {
      console.error("Review submission failed:", err);
      setError(`Failed to submit review: ${err.reason || err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field, value) => {
    setRideDetails(prev => ({ ...prev, [field]: value }));
  };

  const MainMenu = () => (
    <div className="menu">
      <h2>Welcome to RideShare</h2>
      <button onClick={() => setUserType('driver')}>I'm a Driver</button>
      <button onClick={() => setUserType('rider')}>I'm a Rider</button>
    </div>
  );

  const UserDataDisplay = () => {
    if (!userData) return null;
    
    return (
      <div className="user-data">
        <h3>My Data</h3>
        {userType === 'driver' ? (
          <>
            <p>Address: {userData.driverAddress || 'N/A'}</p>
            <p>Collateral: {userData.collateral ? ethers.utils.formatEther(userData.collateral) + ' ETH' : 'N/A'}</p>
            <p>Rating: {userData.rating || 'N/A'}</p>
            <p>Ride Count: {userData.rideCount || '0'}</p>
            <p>Status: {userData.registered ? "Registered" : "Not Registered"}</p>
          </>
        ) : (
          <>
            <p>Address: {userData.riderAddress || 'N/A'}</p>
            <p>Ride Count: {userData.rideCount || '0'}</p>
            <p>Status: {userData.registered ? "Registered" : "Not Registered"}</p>
          </>
        )}
      </div>
    );
  };

  const DriverRegistration = () => (
    <div>
      <h2>Driver Registration</h2>
      <p>Submit 0.001 ETH as collateral to register as a driver</p>
      <button onClick={registerAsDriver} disabled={loading || isRegistered}>
        {isRegistered ? "Already Registered" : loading ? "Processing..." : "Register as Driver"}
      </button>
      <button onClick={resetApp} disabled={loading}>Back</button>
      {error && <div className="error">{error}</div>}
    </div>
  );

  const RiderRegistration = () => (
    <div>
      <h2>Rider Registration</h2>
      <button onClick={registerAsRider} disabled={loading || isRegistered}>
        {isRegistered ? "Already Registered" : loading ? "Processing..." : "Register as Rider"}
      </button>
      <button onClick={resetApp} disabled={loading}>Back</button>
      {error && <div className="error">{error}</div>}
    </div>
  );

  const DriverDashboard = () => {
    return (
      <div>
        <h2>Driver Dashboard</h2>
        <button onClick={checkRegistration} disabled={loading}>
          {loading ? "Refreshing..." : "Refresh My Data"}
        </button>
        <UserDataDisplay />
        <button onClick={resetApp}>Switch User Type</button>
        <div>
          <h3>Submit Ride Proposal</h3>
          <div>
            <label>Ride ID:</label>
            <input
              type="number"
              value={proposalDetails.rideId}
              onChange={(e) => setProposalDetails({...proposalDetails, rideId: e.target.value})}
              placeholder="Enter Ride ID (0, 1, 2...)"
            />
          </div>
          <div>
            <label>Your Price (ETH):</label>
            <input
              type="number"
              value={proposalDetails.price}
              onChange={(e) => setProposalDetails({...proposalDetails, price: e.target.value})}
              placeholder="Enter price in ETH"
              step="0.01"
            />
          </div>
          <button 
            onClick={proposeRidePrice}
            disabled={loading || !proposalDetails.rideId || !proposalDetails.price}
          >
            {loading ? "Processing..." : "Submit Proposal"}
          </button>
          <button onClick={withdrawCollateral} disabled={loading}>
            {loading ? "Processing..." : "Withdraw Collateral"}
          </button>
        </div>
        {error && <div className="error">{error}</div>}
      </div>
    );
  };

  const RiderDashboard = () => {
    return (
      <div>
        <h2>Rider Dashboard</h2>
        <button onClick={checkRegistration} disabled={loading}>
          {loading ? "Refreshing..." : "Refresh My Data"}
        </button>
        <UserDataDisplay />
        <button onClick={resetApp}>Switch User Type</button>
        
        {!activeRide ? (
          <>
            <div className="ride-form">
              <h3>Request a New Ride</h3>
              <div className="form-group">
                <label>Start Location*</label>
                <input 
                  value={rideDetails.startLocation}
                  onChange={(e) => handleInputChange('startLocation', e.target.value)} 
                />
              </div>
              <div className="form-group">
                <label>End Location*</label>
                <input 
                  value={rideDetails.endLocation}
                  onChange={(e) => handleInputChange('endLocation', e.target.value)} 
                />
              </div>
              <div className="form-group">
                <label>Start Time</label>
                <input 
                  value={rideDetails.startTime}
                  onChange={(e) => handleInputChange('startTime', e.target.value)} 
                  placeholder="ASAP"
                />
              </div>
              <div className="form-group">
                <label>Preferences</label>
                <input 
                  value={rideDetails.preferences}
                  onChange={(e) => handleInputChange('preferences', e.target.value)} 
                  placeholder="None"
                />
              </div>
              <button onClick={requestRide} disabled={loading}>
                {loading ? "Processing..." : "Request Ride"}
              </button>
            </div>

            {rideHistory.length > 0 && (
              <div className="ride-history">
                <h3>Your Ride History</h3>
                {rideHistory.map((ride) => (
                  <div key={ride.id} className="ride-item">
                    <p>Ride ID: {ride.id}</p>
                    <p>From: {ride.startLocation} to {ride.endLocation}</p>
                    <p>Status: {ride.status}</p>
                    <button onClick={() => setActiveRide(ride)}>
                      View Details
                    </button>
                  </div>
                ))}
              </div>
            )}
          </>
        ) : (
          <div className="ride-details">
            <h3>Ride Details (ID: {activeRide.id})</h3>
            <p>From: {activeRide.startLocation}</p>
            <p>To: {activeRide.endLocation}</p>
            <p>Status: {activeRide.status}</p>
            {activeRide.price && <p>Price: {activeRide.price} ETH</p>}

            {activeRide.status === RIDE_STATUS.REQUESTED && (
              <div className="offer-selection">
                <h4>Select Best Offer</h4>
                <div>
                  <label>Offer Price (ETH):</label>
                  <input
                    type="number"
                    value={proposalDetails.price}
                    onChange={(e) => setProposalDetails({...proposalDetails, price: e.target.value})}
                    placeholder="Enter price to accept"
                    step="0.01"
                  />
                </div>
                <button 
                  onClick={() => selectBestOffer(activeRide.id, proposalDetails.price)}
                  disabled={loading || !proposalDetails.price}
                >
                  {loading ? "Processing..." : "Accept Offer"}
                </button>
              </div>
            )}

            {activeRide.status === RIDE_STATUS.OFFER_ACCEPTED && (
              <button 
                onClick={() => confirmDeparture(activeRide.id)}
                disabled={loading}
              >
                {loading ? "Processing..." : "Confirm Departure"}
              </button>
            )}

            {activeRide.status === RIDE_STATUS.DEPARTED && (
              <button 
                onClick={() => confirmArrival(activeRide.id)}
                disabled={loading}
              >
                {loading ? "Processing..." : "Confirm Arrival"}
              </button>
            )}

            {activeRide.status === RIDE_STATUS.ARRIVED && (
              <div className="review-section">
                <h4>Submit Review</h4>
                <textarea
                  value={reviewText}
                  onChange={(e) => setReviewText(e.target.value)}
                  placeholder="Your feedback about this ride"
                />
                <button 
                  onClick={() => sendReview(activeRide.id, reviewText)}
                  disabled={loading || !reviewText}
                >
                  {loading ? "Processing..." : "Submit Review"}
                </button>
              </div>
            )}

            {activeRide.status === RIDE_STATUS.COMPLETED && (
              <p className="completed-message">Ride completed successfully!</p>
            )}

            <button onClick={() => setActiveRide(null)}>
              Back to Ride List
            </button>
          </div>
        )}
        {error && <div className="error">{error}</div>}
      </div>
    );
  };

  if (!wallet) return <div>Connecting to blockchain...</div>;
  if (loading) return <div>Processing transaction...</div>;
  if (!userType) return <MainMenu />;
  if (!isRegistered && registrationChecked) {
    return userType === 'driver' 
      ? <DriverRegistration /> 
      : <RiderRegistration />;
  }
  return userType === 'driver' 
    ? <DriverDashboard /> 
    : <RiderDashboard />;
}

export default App;