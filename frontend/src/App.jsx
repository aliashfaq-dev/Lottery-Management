import { useCallback, useEffect, useState } from 'react';
import { BrowserProvider, Contract, formatUnits, parseUnits } from 'ethers';

const LOTTERY_ADDRESS = import.meta.env.VITE_LOTTERY_ADDRESS || '';
const USDC_ADDRESS = import.meta.env.VITE_USDC_ADDRESS || '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
const SEPOLIA_CHAIN_ID = 11155111;
const LOTTERY_ABI = [
  'function owner() view returns (address)',
  'function usdc() view returns (address)',
  'function ticketPrice() view returns (uint256)',
  'function lotteryOpen() view (bool)',
  'function recentWinner() view returns (address)',
  'function getPlayers() view returns (address[])',
  'function getLotteryBalance() view returns (uint256)',
  'function enterLottery()',
  'function pickWinner()',
  'event PlayerEntered(address indexed player)',
  'event WinnerPicked(address indexed winner,uint256 prize)'
];
const USDC_ABI = [
  'function balanceOf(address) view returns (uint256)',
  'function allowance(address,address) view returns (uint256)',
  'function approve(address,uint256) returns (bool)'
];
const short = (s) => s ? s.slice(0,6)+'…'+s.slice(-4) : '—';
const fmt = (v) => Number(v || 0).toLocaleString('en-US',{maximumFractionDigits:6});

export default function App(){
  const [account,setAccount] = useState('');
  const [provider,setProvider] = useState(null);
  const [lottery,setLottery] = useState(null);
  const [usdc,setUsdc] = useState(null);
  const [owner,setOwner] = useState('');
  const [balance,setBalance] = useState('0');
  const [pool,setPool] = useState('0');
  const [price,setPrice] = useState('5');
  const [players,setPlayers] = useState([]);
  const [open,setOpen] = useState(true);
  const [winner,setWinner] = useState('');
  const [isSepolia,setIsSepolia] = useState(false);
  const [loading,setLoading] = useState(false);
  const [notice,setNotice] = useState({type:'info',text:'Connect MetaMask to get started.'});
  const [lastTx,setLastTx] = useState('');

  const refresh = useCallback(async(p,l,u,a)=>{
    if(!p || !l || !a) return;
    try{
      const [bal,priceRaw,playersRaw,poolRaw,ownerRaw,openRaw,winnerRaw] = await Promise.all([
        u.balanceOf(a),l.ticketPrice(),l.getPlayers(),l.getLotteryBalance(),l.owner(),l.lotteryOpen(),l.recentWinner()
      ]);
      setBalance(formatUnits(bal,6)); setPrice(formatUnits(priceRaw,6));
      setPlayers(playersRaw); setPool(formatUnits(poolRaw,6)); setOwner(ownerRaw);
      setOpen(openRaw); setWinner(winnerRaw);
      setIsSepolia((await p.getNetwork()).chainId === BigInt(SEPOLIA_CHAIN_ID));
    }catch(e){setNotice({type:'error',text:e.shortMessage||e.message||'Unable to read contract.'});}
  },[]);

  async function connect(){
    if(!window.ethereum){setNotice({type:'error',text:'MetaMask is not installed. Install MetaMask first.'});return;}
    if(!LOTTERY_ADDRESS){setNotice({type:'error',text:'Set VITE_LOTTERY_ADDRESS in frontend/.env after deploying the contract.'});return;}
    try{
      setLoading(true);
      const p = new BrowserProvider(window.ethereum);
      await window.ethereum.request({method:'eth_requestAccounts'});
      const signer = await p.getSigner(); const a = await signer.getAddress();
      const network = await p.getNetwork();
      if(network.chainId !== BigInt(SEPOLIA_CHAIN_ID)){
        await window.ethereum.request({method:'wallet_switchEthereumChain',params:[{chainId:'0xaa36a7'}]});
      }
      const l = new Contract(LOTTERY_ADDRESS,LOTTERY_ABI,signer);
      const u = new Contract(USDC_ADDRESS,USDC_ABI,signer);
      setAccount(a);setProvider(p);setLottery(l);setUsdc(u);
      await refresh(p,l,u,a);
      setNotice({type:'success',text:'Wallet connected. Ready on Sepolia.'});
    }catch(e){setNotice({type:'error',text:e.shortMessage||e.message||'Wallet connection failed.'});}
    finally{setLoading(false);}
  }

  useEffect(()=>{
    if(!window.ethereum)return;
    const changed=()=>window.location.reload();
    window.ethereum.on?.('accountsChanged',changed);
    window.ethereum.on?.('chainChanged',changed);
    return ()=>{window.ethereum.removeListener?.('accountsChanged',changed);window.ethereum.removeListener?.('chainChanged',changed);};
  },[]);

  async function enter(){
    if(!lottery||!usdc||!account)return;
    try{
      setLoading(true);setNotice({type:'info',text:'Checking USDC allowance…'});
      const ticket=parseUnits(price,6);
      const allowance=await usdc.allowance(account,LOTTERY_ADDRESS);
      if(allowance<ticket){
        setNotice({type:'info',text:'Approve USDC in MetaMask first.'});
        const approveTx=await usdc.approve(LOTTERY_ADDRESS,ticket);
        setLastTx(approveTx.hash);await approveTx.wait();
      }
      setNotice({type:'info',text:'Confirm ticket purchase in MetaMask.'});
      const tx=await lottery.enterLottery();setLastTx(tx.hash);
      setNotice({type:'info',text:'Ticket transaction submitted. Waiting for confirmation…'});
      await tx.wait();await refresh(provider,lottery,usdc,account);
      setNotice({type:'success',text:'You are in the draw! 🎟️'});
    }catch(e){setNotice({type:'error',text:e.shortMessage||e.reason||e.message||'Transaction failed.'});}
    finally{setLoading(false);}
  }

  async function draw(){
    if(!lottery)return;
    try{
      setLoading(true);setNotice({type:'info',text:'Confirm winner selection in MetaMask.'});
      const tx=await lottery.pickWinner();setLastTx(tx.hash);
      setNotice({type:'info',text:'Winner selection submitted. Waiting for confirmation…'});
      await tx.wait();await refresh(provider,lottery,usdc,account);
      setNotice({type:'success',text:'Winner selected and prize sent directly to their wallet!'});
    }catch(e){setNotice({type:'error',text:e.shortMessage||e.reason||e.message||'Draw failed.'});}
    finally{setLoading(false);}
  }

  const isAdmin=account && owner && account.toLowerCase()===owner.toLowerCase();
  return <main className="app">
    <nav className="nav"><a className="brand" href="#"><span className="brand-mark">✦</span> LUCKY<span className="brand-light">DRAW</span></a><div className="nav-right"><span className="network"><i/> Sepolia Testnet</span><button className="wallet-btn" onClick={connect} disabled={loading}>{account?short(account):'Connect Wallet'}</button></div></nav>
    <section className="hero"><div className="eyebrow"><span className="pulse"/> ON-CHAIN LOTTERY · USDC</div><h1>One ticket.<br/><em>One chance.</em></h1><p>Join the draw with USDC. Every ticket contributes to the prize pool—and the winner takes it all.</p><div className="hero-actions"><button className="primary" onClick={account?enter:connect} disabled={loading||!LOTTERY_ADDRESS}>{loading?'Processing…':account?'Buy a ticket':'Connect wallet to play'} <span>↗</span></button><div className="safe-note">Powered by Ethereum Sepolia</div></div><div className="hero-orb"><div className="orb-ring ring1"/><div className="orb-ring ring2"/><div className="orb-core">✦</div><div className="orb-ticket">USDC<br/><b>5.00</b></div></div></section>
    <section className="stats"><article className="stat"><span>Prize pool</span><strong>{fmt(pool)} <small>USDC</small></strong><p>100% goes to the winner</p></article><article className="stat"><span>Ticket price</span><strong>{fmt(price)} <small>USDC</small></strong><p>Fixed price per entry</p></article><article className="stat"><span>Participants</span><strong>{players.length.toString().padStart(2,'0')}</strong><p>Current round</p></article><article className="stat"><span>Round status</span><strong className={open?'status-open':'status-closed'}>{open?'OPEN':'CLOSED'}</strong><p>{open?'Tickets available':'Draw in progress'}</p></article></section>
    <section className="content-grid"><div className="panel"><div className="panel-head"><div><span className="eyebrow">YOUR WALLET</span><h2>Balance & entry</h2></div><span className="wallet-icon">◈</span></div><div className="balance-box"><span>Available USDC</span><strong>{account?fmt(balance):'—'} <small>USDC</small></strong><span className="address">{account?account:'Connect your wallet to see your balance'}</span></div><button className="primary full" onClick={account?enter:connect} disabled={loading||!LOTTERY_ADDRESS}>{account?'Enter lottery · '+fmt(price)+' USDC':'Connect MetaMask'} <span>→</span></button><p className="hint">You may need to approve USDC before your ticket transaction.</p></div>
    <div className="panel"><div className="panel-head"><div><span className="eyebrow">LIVE ROUND</span><h2>Players</h2></div><span className="count">{players.length} entries</span></div><div className="players">{players.length?players.map((p,i)=><div className="player" key={p+i}><span className="avatar">{(i+1).toString().padStart(2,'0')}</span><span>{short(p)}</span><span className="player-tag">TICKET</span></div>):<div className="empty">No tickets yet. Be the first to enter!</div>}</div></div></section>
    {isAdmin&&<section className="admin panel"><div><span className="eyebrow">ADMIN CONTROL</span><h2>Pick the winner</h2><p>Owner-only action. Winner receives the entire USDC balance.</p></div><button className="primary" onClick={draw} disabled={loading||players.length===0}>{loading?'Processing…':'Draw winner →'}</button></section>}
    {winner&&winner!=='0x0000000000000000000000000000000000000000'&&<section className="winner panel"><span className="eyebrow">LAST WINNER</span><h2>🎉 {short(winner)}</h2><p>Prize paid directly to the winner's wallet.</p></section>}
    <section className={'notice '+notice.type}><span>ⓘ</span><div>{notice.text}{lastTx&&<a href={'https://sepolia.etherscan.io/tx/'+lastTx} target="_blank" rel="noreferrer"> View transaction ↗</a>}</div></section>
    <footer><span>LUCKY DRAW / TESTNET</span><span>USDC · Ethereum Sepolia · 0% fee</span><span>Test tokens only. Not real money.</span></footer>
  </main>;
}
