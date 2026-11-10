// Fond animé « SOC » : radar qui balaie, alertes qui apparaissent, flux de logs. 30 fps, pause si l'onglet est caché.
(()=>{const cv=document.getElementById('bg'),x=cv.getContext('2d');let W,H,D;
const AC='125,211,192',RED='192,112,112',YEL='216,166,87';
const LOGS=['[ALERT] T1059.001 powershell enc','[INFO ] auth ok user=svc_etl','[WARN ] 4625 x37 src=10.0.4.12','[INFO ] dns q=cdn.example.org','[ALERT] T1110 brute-force ssh','[INFO ] flow 443 est bytes=18k','[WARN ] sigma:proc_creation_susp','[INFO ] tls handshake ok','[ALERT] T1566 phishing url blocked'];
const lines=[];let blips=[],ang=0,last=0,logT=0;
function rs(){D=devicePixelRatio||1;W=innerWidth;H=innerHeight;cv.width=W*D;cv.height=H*D;cv.style.width=W+'px';cv.style.height=H+'px';x.setTransform(D,0,0,D,0,0)}
addEventListener('resize',rs);rs();
function col(l){return l.includes('ALERT')?RED:l.includes('WARN')?YEL:'168,168,174'}
function frame(t){requestAnimationFrame(frame);if(document.hidden||t-last<33)return;const dt=(t-last)/1000;last=t;
 x.clearRect(0,0,W,H);const cx=W*.78,cy=H*.5,R=Math.min(W,H)*.62;
 for(let i=1;i<=5;i++){x.strokeStyle=`rgba(${AC},${.2-i*.028})`;x.lineWidth=1;x.beginPath();x.arc(cx,cy,R*i/5,0,7);x.stroke()}
 x.strokeStyle=`rgba(${AC},.08)`;x.beginPath();x.moveTo(cx-R,cy);x.lineTo(cx+R,cy);x.moveTo(cx,cy-R);x.lineTo(cx,cy+R);x.stroke();
 const prev=ang;ang=(ang+dt*1.1)%(Math.PI*2);
 for(let i=0;i<40;i++){x.fillStyle=`rgba(${AC},${.14*(1-i/40)})`;x.beginPath();x.moveTo(cx,cy);x.arc(cx,cy,R,ang-i*.022-.022,ang-i*.022);x.closePath();x.fill()}
 x.strokeStyle=`rgba(${AC},.5)`;x.lineWidth=1.5;x.beginPath();x.moveTo(cx,cy);x.lineTo(cx+R*Math.cos(ang),cy+R*Math.sin(ang));x.stroke();
 if(Math.random()<dt*2.2){const a=ang-Math.random()*.2,r=R*(.15+Math.random()*.85);blips.push({x:cx+r*Math.cos(a),y:cy+r*Math.sin(a),l:1,c:[RED,AC,YEL][Math.random()*3|0]})}
 blips=blips.filter(b=>(b.l-=dt*.35)>0);for(const b of blips){x.fillStyle=`rgba(${b.c},${b.l})`;x.beginPath();x.arc(b.x,b.y,3+(1-b.l)*8*(b.c===RED),0,7);x.fill();if(b.c===RED){x.strokeStyle=`rgba(${b.c},${b.l*.5})`;x.beginPath();x.arc(b.x,b.y,6+(1-b.l)*22,0,7);x.stroke()}}
 logT+=dt;if(logT>.9){logT=0;lines.push({t:LOGS[Math.random()*LOGS.length|0],y:H-40})}
 x.font='13px "JetBrainsMono Nerd Font",monospace';for(const l of lines){l.y-=dt*28;const a=Math.max(0,Math.min(.55,l.y/H*.9));x.fillStyle=`rgba(${col(l.t)},${a})`;x.fillText(l.t,40,l.y)}
 while(lines.length&&lines[0].y<-20)lines.shift()}
requestAnimationFrame(frame)})();
