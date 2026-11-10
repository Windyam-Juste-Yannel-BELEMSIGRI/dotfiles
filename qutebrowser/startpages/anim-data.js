// Fond animé « Data » : paquets de données qui circulent dans un pipeline. 30 fps, pause si l'onglet est caché.
(()=>{const cv=document.getElementById('bg'),x=cv.getContext('2d');let W,H,D,last=0;
const AC='125,211,192';
const N=[[300,300,'extract'],[620,200,'clean'],[620,520,'enrich'],[960,360,'join'],[1280,240,'load'],[1280,560,'index'],[1600,400,'serve'],[960,760,'archive'],[1320,860,'report']];
const E=[[0,1],[0,2],[1,3],[2,3],[3,4],[3,5],[4,6],[5,6],[3,7],[7,8],[5,8]];
const P=[];for(let i=0;i<34;i++)P.push({e:i%E.length,t:Math.random(),v:.12+Math.random()*.18});
function rs(){D=devicePixelRatio||1;W=innerWidth;H=innerHeight;cv.width=W*D;cv.height=H*D;cv.style.width=W+'px';cv.style.height=H+'px';x.setTransform(D,0,0,D,0,0)}
addEventListener('resize',rs);rs();
const pt=i=>{const s=Math.max(W/1920,H/1080),ox=(W-1920*s)/2,oy=(H-1080*s)/2;return[ox+N[i][0]*s,oy+N[i][1]*s,s]};
function bz(a,b,t){const[x1,y1]=pt(a),[x2,y2]=pt(b),m=(x1+x2)/2,u=1-t;
 return[u*u*u*x1+3*u*u*t*m+3*u*t*t*m+t*t*t*x2,u*u*u*y1+3*u*u*t*y1+3*u*t*t*y2+t*t*t*y2]}
const pulse=new Array(N.length).fill(0);
function frame(t){requestAnimationFrame(frame);if(document.hidden||t-last<33)return;const dt=(t-last)/1000;last=t;x.clearRect(0,0,W,H);
 x.lineWidth=1.4;x.setLineDash([6,8]);x.strokeStyle=`rgba(${AC},.28)`;x.lineDashOffset=-t/60;
 for(const[a,b]of E){const[x1,y1]=pt(a),[x2,y2]=pt(b),m=(x1+x2)/2;x.beginPath();x.moveTo(x1,y1);x.bezierCurveTo(m,y1,m,y2,x2,y2);x.stroke()}
 x.setLineDash([]);
 for(const p of P){p.t+=dt*p.v;if(p.t>=1){pulse[E[p.e][1]]=1;p.t=0;p.e=(Math.random()*E.length)|0}const[a,b]=E[p.e],[px,py]=bz(a,b,p.t);
  const g=x.createRadialGradient(px,py,0,px,py,9);g.addColorStop(0,`rgba(${AC},.95)`);g.addColorStop(1,`rgba(${AC},0)`);x.fillStyle=g;x.beginPath();x.arc(px,py,9,0,7);x.fill()}
 x.font='15px "JetBrainsMono Nerd Font",monospace';x.textAlign='center';
 N.forEach((n,i)=>{const[nx,ny,s]=pt(i);pulse[i]=Math.max(0,pulse[i]-dt*1.6);const w=124*s,h=48*s;
  x.fillStyle='rgba(42,42,46,.92)';x.strokeStyle=`rgba(${AC},${.55+pulse[i]*.45})`;x.lineWidth=1.4+pulse[i]*1.8;x.shadowColor=`rgba(${AC},${pulse[i]*.8})`;x.shadowBlur=pulse[i]*18;
  x.beginPath();x.roundRect(nx-w/2,ny-h/2,w,h,8);x.fill();x.stroke();x.shadowBlur=0;x.fillStyle='#e8e8ec';x.fillText(n[2],nx,ny+5)})}
requestAnimationFrame(frame)})();
