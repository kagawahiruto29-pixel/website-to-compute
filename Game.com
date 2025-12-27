<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>3D Shooter Android</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
<style>
body { margin:0; overflow:hidden; background:black; }
#ui {
  position:fixed;
  bottom:20px;
  left:50%;
  transform:translateX(-50%);
  color:white;
  font-family:Arial;
}
button {
  font-size:20px;
  padding:15px;
}
</style>
</head>
<body>

<div id="ui">
  <button onclick="shoot()">🔫 SHOOT</button>
</div>

<script src="https://cdn.jsdelivr.net/npm/three@0.152.2/build/three.min.js"></script>

<script>
let scene, camera, renderer;
let bullets = [];
let enemies = [];

init();
animate();

function init() {
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x202020);

  camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
  camera.position.set(0, 1.6, 5);

  renderer = new THREE.WebGLRenderer({antialias:true});
  renderer.setSize(window.innerWidth, window.innerHeight);
  document.body.appendChild(renderer.domElement);

  // Light
  const light = new THREE.DirectionalLight(0xffffff, 1);
  light.position.set(5,10,5);
  scene.add(light);

  scene.add(new THREE.AmbientLight(0xffffff,0.3));

  // Ground
  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(100,100),
    new THREE.MeshStandardMaterial({color:0x444444})
  );
  ground.rotation.x = -Math.PI/2;
  scene.add(ground);

  // Enemies
  for(let i=0;i<5;i++){
    let enemy = new THREE.Mesh(
      new THREE.BoxGeometry(1,2,1),
      new THREE.MeshStandardMaterial({color:0xff0000})
    );
    enemy.position.set(Math.random()*20-10,1,Math.random()*-20);
    scene.add(enemy);
    enemies.push(enemy);
  }

  // Touch look
  let startX = 0;
  document.addEventListener("touchstart", e=>{
    startX = e.touches[0].clientX;
  });

  document.addEventListener("touchmove", e=>{
    let dx = e.touches[0].clientX - startX;
    camera.rotation.y -= dx * 0.002;
    startX = e.touches[0].clientX;
  });

  window.addEventListener("resize", ()=>{
    camera.aspect = window.innerWidth/window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth,window.innerHeight);
  });
}

// Shoot
function shoot(){
  const bullet = new THREE.Mesh(
    new THREE.SphereGeometry(0.1),
    new THREE.MeshBasicMaterial({color:0xffff00})
  );
  bullet.position.copy(camera.position);
  bullet.direction = new THREE.Vector3(0,0,-1).applyQuaternion(camera.quaternion);
  scene.add(bullet);
  bullets.push(bullet);
}

function animate(){
  requestAnimationFrame(animate);

  bullets.forEach((b,i)=>{
    b.position.add(b.direction.clone().multiplyScalar(0.5));

    enemies.forEach((e,ei)=>{
      if(b.position.distanceTo(e.position)<1){
        scene.remove(e);
        enemies.splice(ei,1);
        scene.remove(b);
        bullets.splice(i,1);
      }
    });
  });

  renderer.render(scene,camera);
}
</script>

</body>
</html>
