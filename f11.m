function Sim_Motores_Otto(varargin)
% SIM_MOTORES_OTTO  Simulador del motor Otto de cuatro tiempos con ingreso de datos.
%   Introducción a Motores (MA.01.04) · ISTS · Mecánica Automotriz
%
%   Escriba  Sim_Motores_Otto  en la ventana de comandos.
%   - Panel izquierdo: datos del motor (geometría, operación, combustible,
%     encendido y cotas de distribución), motores de referencia y lugar.
%   - Centro: corte del cilindro animado y diagrama circular de distribución.
%   - Derecha: resultados por ciclo, indicadores y valores instantáneos.
%   - Abajo: P y T frente al ángulo, curvas características o combustión,
%     y el diagrama P-V teórico frente al real.
%
%   Modelo didáctico: ciclo Otto de aire estándar (k = 1,4) frente a un ciclo
%   real de una zona, grado a grado, con ley de Wiebe (a = 5, m = 2), k = 1,32,
%   lazo de bombeo, gases residuales, llenado según el régimen y pérdidas
%   mecánicas orientativas. Funciona en MATLAB R2014b o superior y en GNU Octave.
%
%   Inspirado en el «Simulador de Motores» en Flash usado en clase; es un
%   desarrollo nuevo, en español y con ingreso de datos.

S.in    = valoresBase();
S.theta = 0;  S.playing = true;  S.speed = 4;  S.unit = 1;  S.tab = 1;
S.h     = struct();

fig = figure('Name','Simulador de Motores Otto - Introducción a Motores (ISTS)', ...
    'NumberTitle','off','Color','w','MenuBar','none','ToolBar','figure', ...
    'Units','pixels','Position',[40 40 1360 780]);
setappdata(fig,'S',S);
crearInterfaz(fig);
recalcular(fig);

% --- modo de prueba: Sim_Motores_Otto(nCuadros, 'archivo.png') ---
if nargin >= 1 && isnumeric(varargin{1})
    for k = 1:varargin{1}
        S = getappdata(fig,'S'); S.theta = mod(S.theta + 7, 720); setappdata(fig,'S',S);
        actualizarCuadro(fig); drawnow;
    end
    if nargin >= 2, print(fig, '-dpng', '-r90', varargin{2}); end
    return
end

% --- bucle de animación ---
while ishandle(fig)
    S = getappdata(fig,'S');
    if S.playing
        S.theta = mod(S.theta + S.speed, 720);
        setappdata(fig,'S',S);
        actualizarCuadro(fig);
    end
    drawnow;
    pause(0.03);
end
end

% =====================================================================
%  DATOS
% =====================================================================
function in = valoresBase()
in = struct('D',84,'L',81,'lb',135,'cil',4,'Rc',9.9,'n',3000,'mariposa',100, ...
    'Patm',101.3,'Tatm',20,'fuel',2,'lambda',1.0,'util',80,'avance',25,'dur',50, ...
    'AAA',10,'RCA',40,'AAE',45,'RCE',10);
end

function F = campos()
% {campo, etiqueta, unidad, mínimo, máximo}
F = { 'D','Diámetro (alesaje) D','mm',50,110;
      'L','Carrera L','mm',50,110;
      'lb','Longitud de biela l','mm',90,200;
      'cil','Número de cilindros','',1,8;
      'Rc','Relación de compresión','Rc',6,14;
      'n','Régimen n','rpm',800,7000;
      'mariposa','Apertura de mariposa','%',5,100;
      'Patm','Presión atmosférica','kPa',60,105;
      'Tatm','Temperatura ambiente','°C',0,40;
      'lambda','Factor lambda (1 = esteq.)','',0.6,1.6;
      'util','Calor útil','%',50,95;
      'avance','Avance del encendido','° aPMS',0,50;
      'dur','Duración de la combustión','°',20,100;
      'AAA','AAA (aval. apertura adm.)','°',0,40;
      'RCA','RCA (retraso cierre adm.)','°',0,80;
      'AAE','AAE (avance apertura esc.)','°',20,80;
      'RCE','RCE (retraso cierre esc.)','°',0,40 };
end

function C = combustibles()
% nombre, relación estequiométrica A/C, PCI (J/kg), límite de detonación (K)
C = struct('nombre',{'Gasolina Extra (87 oct.)','Gasolina Súper (92 oct.)','Etanol E100','GLP'}, ...
    'afr',{14.7,14.7,9.0,15.6},'pci',{43.4e6,43.4e6,26.8e6,46.1e6},'tlim',{1000,1060,1180,1160});
end

function P = motoresRef()
P = { '— Cargar motor de referencia —',      [];
      'Motor de la guía (84 × 81 mm)',        [84 81 135 4 9.9];
      'Suzuki G13B (banco del taller)',       [74 75.5 126 4 9.5];
      'Daihatsu CB-20 (maqueta)',             [76 73 122 3 9.5];
      'Nissan A14 (maqueta)',                 [76 77 128 4 9.0];
      'Hyundai G4ED 1.6 (maqueta)',           [76.5 87 145 4 10.0];
      'Chevrolet Monza 2.0 (maqueta)',        [86 86 143 4 9.2] };
end

function L = lugares()
L = { '— Lugar —', [];  'Nivel del mar', [101.3 20];  'Loja (2 060 m)', [79.0 16];  'Quito (2 850 m)', [72.0 14] };
end

% =====================================================================
%  INTERFAZ
% =====================================================================
function crearInterfaz(fig)
S = getappdata(fig,'S');
F = campos();  C = combustibles();  P = motoresRef();  L = lugares();
bg = [0.96 0.97 0.98];

pnl = uipanel(fig,'Units','normalized','Position',[0.005 0.01 0.19 0.98], ...
    'Title','Datos del motor','FontWeight','bold','BackgroundColor',bg);
nF = size(F,1);  hRow = 1/(nF + 6.2);
y = 1 - 1.15*hRow;
S.h.preset = uicontrol(pnl,'Style','popupmenu','Units','normalized','Position',[0.04 y 0.92 hRow*0.9], ...
    'String',P(:,1),'Callback',@(s,e) cbPreset(fig));
y = y - hRow;
S.h.lugar = uicontrol(pnl,'Style','popupmenu','Units','normalized','Position',[0.04 y 0.92 hRow*0.9], ...
    'String',L(:,1),'Callback',@(s,e) cbLugar(fig));
y = y - hRow;
S.h.fuel = uicontrol(pnl,'Style','popupmenu','Units','normalized','Position',[0.04 y 0.92 hRow*0.9], ...
    'String',{C.nombre},'Value',S.in.fuel,'Callback',@(s,e) cbEntrada(fig));
y = y - 0.3*hRow;
S.h.ed = zeros(nF,1);
for k = 1:nF
    y = y - hRow;
    uicontrol(pnl,'Style','text','Units','normalized','Position',[0.03 y 0.58 hRow*0.8], ...
        'String',F{k,2},'HorizontalAlignment','left','BackgroundColor',bg,'FontSize',8);
    S.h.ed(k) = uicontrol(pnl,'Style','edit','Units','normalized','Position',[0.62 y+0.1*hRow 0.21 hRow*0.85], ...
        'String',num2str(S.in.(F{k,1})),'BackgroundColor','w','Callback',@(s,e) cbEntrada(fig));
    uicontrol(pnl,'Style','text','Units','normalized','Position',[0.84 y 0.15 hRow*0.8], ...
        'String',F{k,3},'HorizontalAlignment','left','BackgroundColor',bg,'FontSize',8);
end
y = y - 1.25*hRow;
uicontrol(pnl,'Style','pushbutton','Units','normalized','Position',[0.04 y 0.44 hRow*1.05], ...
    'String','Restablecer','Callback',@(s,e) cbReset(fig));
uicontrol(pnl,'Style','pushbutton','Units','normalized','Position',[0.52 y 0.44 hRow*1.05], ...
    'String','Cerrar','Callback',@(s,e) close(fig));
y = y - 1.1*hRow;
S.h.nota = uicontrol(pnl,'Style','text','Units','normalized','Position',[0.03 y 0.94 hRow], ...
    'String','Escriba un valor y pulse Enter.','HorizontalAlignment','left','BackgroundColor',bg, ...
    'FontSize',8,'ForegroundColor',[0.4 0.45 0.5]);

% ---- banco de pruebas ----
S.h.axM = axes('Parent',fig,'Units','normalized','Position',[0.20 0.42 0.23 0.56]);
S.h.axF = axes('Parent',fig,'Units','normalized','Position',[0.44 0.42 0.22 0.56]);
% ---- controles de animación ----
S.h.tiempo = uicontrol(fig,'Style','text','Units','normalized','Position',[0.20 0.375 0.20 0.035], ...
    'String','1. ADMISIÓN','FontSize',14,'FontWeight','bold','BackgroundColor','w','HorizontalAlignment','left');
S.h.play = uicontrol(fig,'Style','togglebutton','Units','normalized','Position',[0.41 0.378 0.06 0.033], ...
    'String','Pausa','Value',1,'FontWeight','bold','Callback',@(s,e) cbPlay(fig));
uicontrol(fig,'Style','text','Units','normalized','Position',[0.475 0.385 0.05 0.022], ...
    'String','Velocidad','BackgroundColor','w','HorizontalAlignment','right','FontSize',8);
S.h.vel = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.53 0.385 0.13 0.022], ...
    'Min',1,'Max',12,'Value',S.speed,'Callback',@(s,e) cbVel(fig));
S.h.angTxt = uicontrol(fig,'Style','text','Units','normalized','Position',[0.20 0.343 0.12 0.025], ...
    'String','Ángulo del cigüeñal','BackgroundColor','w','HorizontalAlignment','left','FontSize',8);
S.h.ang = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.32 0.345 0.34 0.022], ...
    'Min',0,'Max',719,'Value',0,'SliderStep',[1/719 30/719],'Callback',@(s,e) cbAng(fig));

% ---- resultados ----
S.h.res = uicontrol(fig,'Style','text','Units','normalized','Position',[0.675 0.345 0.32 0.645], ...
    'String','','HorizontalAlignment','left','BackgroundColor',[0.97 0.98 0.99], ...
    'FontName','Courier New','FontSize',8);
uicontrol(fig,'Style','text','Units','normalized','Position',[0.675 0.302 0.06 0.025], ...
    'String','Presión en','BackgroundColor','w','HorizontalAlignment','left','FontSize',8);
S.h.unit = uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[0.735 0.300 0.08 0.03], ...
    'String',{'bar','kgf/cm²'},'Callback',@(s,e) cbUnidad(fig));
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[0.82 0.300 0.085 0.032], ...
    'String','Copiar resultados','Callback',@(s,e) cbCopiar(fig));
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[0.91 0.300 0.085 0.032], ...
    'String','Guardar imagen','Callback',@(s,e) cbImagen(fig));

% ---- gráficas ----
S.h.tab = uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[0.25 0.305 0.25 0.03], ...
    'String',{'Presión y temperatura frente al ángulo','Curvas características (potencia y par)', ...
              'Combustión (masa quemada y liberación de calor)'},'Callback',@(s,e) cbTab(fig));
S.h.axL = axes('Parent',fig,'Units','normalized','Position',[0.25 0.065 0.37 0.19]);
S.h.axR = axes('Parent',fig,'Units','normalized','Position',[0.25 0.065 0.37 0.19], ...
    'Color','none','YAxisLocation','right','XTickLabel',[],'Box','off');
S.h.axPV = axes('Parent',fig,'Units','normalized','Position',[0.735 0.065 0.25 0.19]);
setappdata(fig,'S',S);
end

% =====================================================================
%  CALLBACKS
% =====================================================================
function cbEntrada(fig)
S = getappdata(fig,'S');  F = campos();
for k = 1:size(F,1)
    v = str2double(strrep(get(S.h.ed(k),'String'),',','.'));
    if isnan(v), v = S.in.(F{k,1}); end
    v = min(F{k,5}, max(F{k,4}, v));
    if strcmp(F{k,1},'cil'), v = round(v); end
    S.in.(F{k,1}) = v;
end
S.in.fuel = get(S.h.fuel,'Value');
if S.in.lb < 0.9*S.in.L
    S.in.lb = round(0.9*S.in.L);
    set(S.h.nota,'String','La biela debe ser más larga que 0,9·L: se corrigió.');
else
    set(S.h.nota,'String','Escriba un valor y pulse Enter.');
end
for k = 1:size(F,1), set(S.h.ed(k),'String',num2str(S.in.(F{k,1}))); end
setappdata(fig,'S',S);
recalcular(fig);
end

function cbPreset(fig)
S = getappdata(fig,'S');  P = motoresRef();  v = P{get(S.h.preset,'Value'),2};
if isempty(v), return; end
S.in.D = v(1); S.in.L = v(2); S.in.lb = v(3); S.in.cil = v(4); S.in.Rc = v(5);
escribirEntradas(S); setappdata(fig,'S',S);
set(S.h.nota,'String','Valores de referencia: verifíquelos en el manual.');
recalcular(fig);
end

function cbLugar(fig)
S = getappdata(fig,'S');  L = lugares();  v = L{get(S.h.lugar,'Value'),2};
if isempty(v), return; end
S.in.Patm = v(1); S.in.Tatm = v(2);
escribirEntradas(S); setappdata(fig,'S',S); recalcular(fig);
end

function cbReset(fig)
S = getappdata(fig,'S'); S.in = valoresBase();
set(S.h.preset,'Value',1); set(S.h.lugar,'Value',1); set(S.h.fuel,'Value',S.in.fuel);
escribirEntradas(S); setappdata(fig,'S',S); recalcular(fig);
end

function escribirEntradas(S)
F = campos();
for k = 1:size(F,1), set(S.h.ed(k),'String',num2str(S.in.(F{k,1}))); end
end

function cbPlay(fig)
S = getappdata(fig,'S'); S.playing = logical(get(S.h.play,'Value'));
if S.playing, set(S.h.play,'String','Pausa'); else, set(S.h.play,'String','Reproducir'); end
setappdata(fig,'S',S);
end

function cbVel(fig)
S = getappdata(fig,'S'); S.speed = round(get(S.h.vel,'Value')); setappdata(fig,'S',S);
end

function cbAng(fig)
S = getappdata(fig,'S'); S.playing = false; set(S.h.play,'Value',0,'String','Reproducir');
S.theta = round(get(S.h.ang,'Value')); setappdata(fig,'S',S); actualizarCuadro(fig);
end

function cbUnidad(fig)
S = getappdata(fig,'S'); S.unit = get(S.h.unit,'Value'); setappdata(fig,'S',S);
dibujarGraficas(fig); actualizarCuadro(fig);
end

function cbTab(fig)
S = getappdata(fig,'S'); S.tab = get(S.h.tab,'Value'); setappdata(fig,'S',S);
dibujarGraficas(fig); actualizarCuadro(fig);
end

function cbCopiar(fig)
S = getappdata(fig,'S'); txt = sprintf('%s\n', S.lineas{:});
try
    clipboard('copy', txt);
    set(S.h.nota,'String','Resultados copiados al portapapeles.');
catch
    fid = fopen('Resultados_Simulador_Otto.txt','w'); fprintf(fid,'%s',txt); fclose(fid);
    set(S.h.nota,'String','Guardado en Resultados_Simulador_Otto.txt');
end
end

function cbImagen(fig)
S = getappdata(fig,'S');
nom = sprintf('Simulador_Otto_%s.png', datestr(now,'yyyymmdd_HHMMSS'));
print(fig,'-dpng','-r120',nom);
set(S.h.nota,'String',['Imagen guardada: ' nom]);
end

% =====================================================================
%  CÁLCULO
% =====================================================================
function recalcular(fig)
S = getappdata(fig,'S');
S.r = simular(S.in, []);
ns = 1000:250:7000;  S.cv = zeros(numel(ns),4);
for k = 1:numel(ns)
    c = simular(S.in, ns(k));
    S.cv(k,:) = [ns(k), c.Pe/1000, c.Me, c.ge];
end
setappdata(fig,'S',S);
dibujarMotorFijo(fig); dibujarFases(fig); dibujarGraficas(fig); actualizarCuadro(fig);
end

function r = simular(in, nOv)
C = combustibles(); fu = C(in.fuel);
n = in.n; if ~isempty(nOv), n = nOv; end
R = 287; k = 1.32; kid = 1.4; cvAir = 718;
rk = in.L/2; lam = rk/in.lb;
Sp = pi*(in.D/10)^2/4;  Vu = Sp*in.L/10;  Vc = Vu/(in.Rc-1);         % cm2, cm3
th = 0:719;  t = th*pi/180;
x  = rk*((1-cos(t)) + (1/lam)*(1-sqrt(1-lam^2*sin(t).^2)));          % mm
V  = Vc + Sp*x/10;                                                    % cm3
rpmF = n/6000;  Patm = in.Patm;  Tatm = in.Tatm + 273.15;
Padm = Patm*(1-0.92*(1-in.mariposa/100)^2)*(1-0.05*rpmF^2);          % kPa
Pesc = Patm*(1.05+0.25*rpmF^2);
xr = min(0.3, (1/in.Rc)*(Pesc/Padm)^(1/k));
T1 = (1-xr)*(Tatm+15) + xr*850;
IVC = round(180+in.RCA);  EVO = round(540-in.AAE);
nopt = 1500 + 60*in.RCA;
fill = max(0.55, 1.05 - 0.5*((n-nopt)/6000)^2);
mtot = fill*Padm*1e3*V(181)*1e-6/(R*T1);
pIVC = mtot*R*T1/(V(IVC+1)*1e-6)/1e5;
mair = (1-xr)*mtot;  rhoAtm = Patm*1e3/(R*Tatm);  etaV = mair/(rhoAtm*Vu*1e-6);
lb_ = in.lambda;  mf = mair/(lb_*fu.afr);
misfire = lb_ > 1.5 || lb_ < 0.6;
if lb_ < 1, Q = mair/fu.afr*fu.pci*in.util/100; else, Q = mf*fu.pci*in.util/100; end
if misfire, Q = 0; end
dur = in.dur*(1+1.5*(lb_-1)^2);  ts = 360 - in.avance;
wiebe = @(a) 1 - exp(-5*max(0,(a-ts)/dur).^3);
p = zeros(1,720); T = p; xb = p;  P1 = Padm/100;
for i = 0:IVC, p(i+1) = P1 + (Pesc/100-P1)*exp(-i/15); T(i+1) = T1; end
for i = 180:IVC, p(i+1) = P1 + (pIVC-P1)*(i-180)/max(1,IVC-180); end
for i = IVC:EVO-1
    dV = (V(i+2)-V(i+1))*1e-6;  Vm = 0.5*(V(i+1)+V(i+2))*1e-6;
    xb(i+2) = wiebe(i+1);  xb(i+1) = wiebe(i);
    dQ = Q*(xb(i+2)-xb(i+1));  pa = p(i+1)*1e5;
    p(i+2) = (pa + ((k-1)*dQ - k*pa*dV)/Vm)/1e5;
    T(i+2) = p(i+2)*1e5*V(i+2)*1e-6/(mtot*R);
end
pE = p(EVO+1); TE = T(EVO+1); pe = Pesc/100;
for i = EVO+1:719
    p(i+1) = pe + (pE-pe)*exp(-(i-EVO)/18);
    T(i+1) = max(TE*(p(i+1)/pE)^((k-1)/k), 600);
end
xb(EVO+1:end) = ~misfire;
W = sum(0.5*(p + [p(2:end) p(1)]).*([V(2:end) V(1)] - V))*0.1;       % J
pmi = W/(Vu*0.1);
pmf = (75 + 10*n/1000 + 3*(n/1000)^2)/100;
pme = pmi - pmf;
Pe = pme*1e5*Vu*1e-6*in.cil*n/120;  Pi = W*in.cil*n/120;  w = 2*pi*n/60;
fuelH = mf*in.cil*n/2*60;  Qf = mf*fu.pci*in.cil*n/120;
% ciclo Otto ideal con el mismo calor
V1 = V(181); V2 = V(361);
T2 = T1*(V1/V2)^(kid-1); P2 = P1*(V1/V2)^kid; T3 = T2 + Q/(mtot*cvAir); P3 = P2*T3/T2;
pid = P1*ones(1,720); Tid = T1*ones(1,720);
ic = 181:360; pid(ic) = P1*(V1./V(ic)).^kid; Tid(ic) = T1*(V1./V(ic)).^(kid-1);
ie = 361:540; pid(ie) = P3*(V2./V(ie)).^kid; Tid(ie) = T3*(V2./V(ie)).^(kid-1);
[pmax, im] = max(p);
Tu = T1*(pmax/P1)^((k-1)/k);
r = struct('th',th,'V',V,'p',p,'T',T,'xb',xb,'pid',pid,'Tid',Tid,'Vu',Vu,'Vc',Vc, ...
    'Vt',Vu*in.cil,'Sp',Sp,'lam',lam,'Padm',Padm,'ts',ts,'dur',dur,'Q',Q,'etaV',etaV,'W',W, ...
    'pmi',pmi,'pmf',pmf,'pme',pme,'Pe',Pe,'Me',Pe/w,'Mi',Pi/w,'etae',Pe/max(Qf,eps), ...
    'etaid',1-1/in.Rc^(kid-1),'ge',fuelH/(Pe/1000)*1000,'fuelH',fuelH,'pmax',pmax,'thmax',im-1, ...
    'Tmax',max(T),'pidmax',max(pid),'Tidmax',max(Tid),'knock',Tu/fu.tlim*(~misfire), ...
    'misfire',misfire,'vm',in.L/1000*n/30,'n',n,'IVC',IVC,'EVO',EVO);
if Pe <= 0, r.ge = NaN; end
end

% =====================================================================
%  DIBUJO
% =====================================================================
function c = col(nombre)
switch nombre
    case 'adm',  c = [0.35 0.66 0.90];
    case 'comp', c = [0.36 0.43 0.88];
    case 'comb', c = [0.94 0.55 0.18];
    case 'esc',  c = [0.60 0.64 0.68];
    case 'real', c = [0.85 0.28 0.06];
    case 'ideal',c = [0.29 0.33 0.39];
    case 'temp', c = [0.76 0.15 0.36];
    case 'pot',  c = [0.04 0.48 0.46];
    case 'metal',c = [0.79 0.82 0.85];
    case 'acero',c = [0.49 0.54 0.60];
    otherwise,   c = [0 0 0];
end
end

function [nom, c] = tiempoDe(i)
if i < 180, nom = '1. ADMISIÓN'; c = col('adm');
elseif i < 360, nom = '2. COMPRESIÓN'; c = col('comp');
elseif i < 540, nom = '3. EXPANSIÓN'; c = col('comb');
else, nom = '4. ESCAPE'; c = col('esc');
end
end

function h = alzada(S, i, cual)
if strcmp(cual,'adm'), ab = -S.in.AAA; ci = 180 + S.in.RCA; else, ab = 540 - S.in.AAE; ci = 720 + S.in.RCE; end
h = 0;
for s = [-720 0 720]
    x = i + s;
    if x >= ab && x <= ci, h = max(h, 0.5*(1-cos(2*pi*(x-ab)/(ci-ab)))); end
end
end

function g = geo(in)
g.D = in.D; g.Rk = in.L/2; g.lb = in.lb; g.hc = in.L/(in.Rc-1); g.hp = 0.72*in.D;
g.pinUp = 0.42*g.hp; g.wall = 9;
g.yPMS = g.Rk + g.lb + g.pinUp;  g.yHead = g.yPMS + g.hc;
g.vx = 0.27*in.D; g.vd = 0.30*in.D;
end

function dibujarMotorFijo(fig)
S = getappdata(fig,'S'); ax = S.h.axM; g = geo(S.in);
cla(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
D = g.D; Rk = g.Rk; w = g.wall; yH = g.yHead; ext = D/2 + w + 14;
rect = @(x0,y0,ww,hh,fc,ec) patch('Parent',ax,'XData',[x0 x0+ww x0+ww x0],'YData',[y0 y0 y0+hh y0+hh], ...
    'FaceColor',fc,'EdgeColor',ec);
rect(-(D/2+34), -(Rk+26), D+68, 2*Rk+48, [0.95 0.96 0.97], col('acero'));          % cárter
rect(-ext, Rk+20, ext-D/2, yH-(Rk+20), col('metal'), 'none');                      % bloque
rect(D/2, Rk+20, ext-D/2, yH-(Rk+20), col('metal'), 'none');
rect(-ext+5, Rk+g.lb-10, 6, yH-6-(Rk+g.lb-10), [0.80 0.89 0.96], 'none');          % agua
rect(ext-11, Rk+g.lb-10, 6, yH-6-(Rk+g.lb-10), [0.80 0.89 0.96], 'none');
plot(ax,[-D/2 -D/2 NaN D/2 D/2],[Rk+20 yH NaN Rk+20 yH],'Color',[0.17 0.21 0.27],'LineWidth',2);
H.gas   = patch('Parent',ax,'XData',[0 0 0 0],'YData',[0 0 0 0],'FaceColor',col('adm'),'EdgeColor','none');
H.llama = patch('Parent',ax,'XData',0,'YData',0,'FaceColor',[1 0.78 0.35],'EdgeColor',[0.94 0.55 0.18]);
rect(-ext, yH, 2*ext, 34, col('metal'), col('acero'));                             % culata
for sg = [-1 1]
    if sg < 0, cc = mezcla(col('adm'),0.45); else, cc = mezcla(col('esc'),0.45); end
    patch('Parent',ax,'XData',sg*[g.vx-g.vd/2, g.vx+g.vd/2, ext, ext], ...
        'YData',[yH yH yH+24 yH+10],'FaceColor',cc,'EdgeColor','none');
end
H.valv(1) = patch('Parent',ax,'XData',0,'YData',0,'FaceColor',col('pot'),'EdgeColor','k');
H.valv(2) = patch('Parent',ax,'XData',0,'YData',0,'FaceColor',col('acero'),'EdgeColor','k');
H.mue(1) = plot(ax,0,0,'Color',col('acero'),'LineWidth',1);
H.mue(2) = plot(ax,0,0,'Color',col('acero'),'LineWidth',1);
rect(-4, yH, 8, 52, col('acero'), 'none'); rect(-6, yH+48, 12, 16, 'w', col('acero'));   % bujía
H.chispa = plot(ax,0,0,'Color',[0.98 0.69 0.02],'LineWidth',2);
H.piston = patch('Parent',ax,'XData',0,'YData',0,'FaceColor',[0.66 0.71 0.75],'EdgeColor',[0.17 0.21 0.27]);
H.aros   = plot(ax,0,0,'Color',[0.17 0.21 0.27],'LineWidth',1);
H.contra = patch('Parent',ax,'XData',0,'YData',0,'FaceColor',[0.72 0.76 0.80],'EdgeColor','none');
H.mani   = plot(ax,[0 0],[0 0],'Color',col('real'),'LineWidth',7);
H.biela  = plot(ax,[0 0],[0 0],'Color',col('pot'),'LineWidth',5);
H.pernos = plot(ax,[0 0 0],[0 0 0],'o','MarkerSize',7,'MarkerFaceColor','w','MarkerEdgeColor','k','LineStyle','none');
xL = -ext - 6;
plot(ax,[xL -D/2],[g.yPMS g.yPMS],'--','Color',col('comp'));
plot(ax,[xL -D/2],[g.yPMS-S.in.L g.yPMS-S.in.L],'--','Color',col('comp'));
text(xL-2, g.yPMS, 'PMS','Parent',ax,'HorizontalAlignment','right','FontSize',8,'FontWeight','bold');
text(xL-2, g.yPMS-S.in.L, 'PMI','Parent',ax,'HorizontalAlignment','right','FontSize',8,'FontWeight','bold');
text(-ext+8, yH+46, 'Admisión','Parent',ax,'HorizontalAlignment','center','FontSize',8);
text(ext-8, yH+46, 'Escape','Parent',ax,'HorizontalAlignment','center','FontSize',8);
text(0, -(Rk+40), sprintf('D %g × L %g mm · %d cil. · Rc %g:1', S.in.D, S.in.L, S.in.cil, S.in.Rc), ...
    'Parent',ax,'HorizontalAlignment','center','FontSize',8,'Color',[0.35 0.4 0.45]);
xlim(ax,[-(ext+30) ext+12]); ylim(ax,[-(Rk+46) yH+68]);
S.h.mot = H; setappdata(fig,'S',S);
end

function c = mezcla(c, a)
c = c*a + (1-a);
end

function dibujarFases(fig)
S = getappdata(fig,'S'); ax = S.h.axF; in = S.in;
cla(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
P = @(d,r) deal(r*sind(d), r*cosd(d));            % 0° arriba, sentido horario
arco = @(a,b,r,c) plot(ax, r*sind(linspace(a,b,120)), r*cosd(linspace(a,b,120)),'Color',c,'LineWidth',9);
plot(ax,[0 0],[-1.25 1.25],':','Color',[0.8 0.8 0.8]); plot(ax,[-1.25 1.25],[0 0],':','Color',[0.8 0.8 0.8]);
arco(-in.AAA, 180+in.RCA, 1.00, col('adm'));
arco(180+in.RCA, 360, 0.85, col('comp'));
arco(360, 540-in.AAE, 0.70, col('comb'));
arco(540-in.AAE, 720+in.RCE, 0.55, col('esc'));
[x,y] = P(360-in.avance, 0.775);
plot(ax,x,y,'p','MarkerSize',14,'MarkerFaceColor',[0.98 0.69 0.02],'MarkerEdgeColor','k');
et = @(d,r,s) text(r*sind(d), r*cosd(d), s,'Parent',ax,'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');
et(-in.AAA, 1.17, sprintf('AAA %g°',in.AAA));  et(180+in.RCA, 1.17, sprintf('RCA %g°',in.RCA));
et(540-in.AAE, 1.17, sprintf('AAE %g°',in.AAE)); et(720+in.RCE+16, 1.17, sprintf('RCE %g°',in.RCE));
text(0, 1.36, 'PMS','Parent',ax,'HorizontalAlignment','center','FontWeight','bold','Color',[0.35 0.4 0.45]);
text(0,-1.33, 'PMI','Parent',ax,'HorizontalAlignment','center','FontWeight','bold','Color',[0.35 0.4 0.45]);
S.h.aguja  = plot(ax,[0 0],[0 1.1],'k','LineWidth',2.5);
plot(ax,0,0,'ko','MarkerFaceColor','k','MarkerSize',5);
S.h.centro = text(0,-0.18,'','Parent',ax,'HorizontalAlignment','center','FontWeight','bold','FontSize',10);
S.h.vuelta = text(0,-0.31,'','Parent',ax,'HorizontalAlignment','center','FontSize',8,'Color',[0.35 0.4 0.45]);
dA = in.AAA+180+in.RCA; dE = in.AAE+180+in.RCE;
txt = {sprintf('Admisión %g° · Compresión %g°', dA, 180-in.RCA), ...
       sprintf('Expansión %g° · Escape %g°', 180-in.AAE, dE), ...
       sprintf('Cruce de válvulas %g° · chispa %g° aPMS', in.AAA+in.RCE, in.avance)};
text(0,-1.55, txt,'Parent',ax,'HorizontalAlignment','center','VerticalAlignment','top','FontSize',8);
title(ax,'Diagrama de distribución','FontSize',10);
xlim(ax,[-1.45 1.45]); ylim(ax,[-1.95 1.5]);
setappdata(fig,'S',S);
end

function v = pU(S, p)
if S.unit == 1, v = p; else, v = p*1.01972; end
end

function s = pLab(S)
if S.unit == 1, s = 'bar'; else, s = 'kgf/cm^2'; end
end

function dibujarGraficas(fig)
S = getappdata(fig,'S'); r = S.r; in = S.in; aL = S.h.axL; aR = S.h.axR; aP = S.h.axPV;
cla(aL); cla(aR); try, legend(aL,'off'); catch, end; hold(aL,'on'); hold(aR,'on');
set(aR,'Color','none','YAxisLocation','right','XTickLabel',[],'Box','off','XTick',[]);
switch S.tab
    case 1
        pM = pU(S, max(r.pidmax, r.pmax)*1.08); tM = (max(r.Tidmax, r.Tmax)-273.15)*1.08;
        patch('Parent',aL,'XData',[0 180+in.RCA 180+in.RCA 0],'YData',[0 0 pM pM],'FaceColor',mezcla(col('adm'),0.12),'EdgeColor','none');
        patch('Parent',aL,'XData',[540-in.AAE 720 720 540-in.AAE],'YData',[0 0 pM pM],'FaceColor',mezcla(col('esc'),0.15),'EdgeColor','none');
        plot(aR, r.th, r.Tid-273.15, '--','Color',col('temp'),'LineWidth',1);
        plot(aR, r.th, r.T-273.15, '-','Color',col('temp'),'LineWidth',1.4);
        h1 = plot(aL, r.th, pU(S,r.p), '-','Color',col('real'),'LineWidth',2);
        h2 = plot(aL, r.th, pU(S,r.pid), '--','Color',col('ideal'),'LineWidth',1.3);
        h3 = plot(aL, NaN, NaN, '-','Color',col('temp'),'LineWidth',1.4);
        h4 = plot(aL, NaN, NaN, '--','Color',col('temp'),'LineWidth',1);
        ev = {180+in.RCA,'RCA',col('adm'); r.ts,'Chispa',[0.9 0.47 0]; 540-in.AAE,'AAE',col('esc')};
        for k = 1:3
            plot(aL,[ev{k,1} ev{k,1}],[0 pM],':','Color',ev{k,3},'LineWidth',1.2);
            text(ev{k,1}, pM*0.97, ev{k,2},'Parent',aL,'FontSize',7,'Color',ev{k,3},'HorizontalAlignment','center','VerticalAlignment','top');
        end
        S.h.cur  = plot(aL,[0 0],[0 pM],'k-','LineWidth',1);
        S.h.curP = plot(aL,0,0,'o','MarkerFaceColor',col('real'),'MarkerEdgeColor','k','MarkerSize',6);
        S.h.curT = plot(aR,0,0,'o','MarkerFaceColor',col('temp'),'MarkerEdgeColor','k','MarkerSize',5);
        set(aL,'XLim',[0 720],'YLim',[0 pM],'XTick',0:90:720); set(aR,'XLim',[0 720],'YLim',[0 tM]);
        xlabel(aL,'Ángulo del cigüeñal \theta (°)'); ylabel(aL,['Presión (' pLab(S) ')']); ylabel(aR,'Temperatura (°C)');
        legend(aL,[h1 h2 h3 h4],{'Presión real','Presión teórica','Temp. real','Temp. teórica'},'Location','northwest','FontSize',7);
    case 2
        ns = S.cv(:,1); Pe = max(0,S.cv(:,2)); Me = max(0,S.cv(:,3));
        [pMx,iP] = max(Pe); [mMx,iM] = max(Me); pM = pMx*1.3; mM = mMx*1.3;
        patch('Parent',aL,'XData',[ns(iM) ns(iP) ns(iP) ns(iM)],'YData',[0 0 pM pM],'FaceColor',mezcla(col('pot'),0.12),'EdgeColor','none');
        plot(aR, ns, Me, '-','Color',col('real'),'LineWidth',2);
        plot(aR, ns(iM), Me(iM), 'o','MarkerFaceColor',col('real'),'MarkerEdgeColor','k');
        h1 = plot(aL, ns, Pe, '-','Color',col('pot'),'LineWidth',2);
        plot(aL, ns(iP), Pe(iP), 'o','MarkerFaceColor',col('pot'),'MarkerEdgeColor','k');
        h2 = plot(aL, NaN, NaN, '-','Color',col('real'),'LineWidth',2);
        plot(aL,[in.n in.n],[0 pM],'k:','LineWidth',1.2);
        S.h.cur = []; S.h.curP = []; S.h.curT = [];
        set(aL,'XLim',[1000 7000],'YLim',[0 pM],'XTick',1000:1000:7000); set(aR,'XLim',[1000 7000],'YLim',[0 mM]);
        xlabel(aL,'Régimen n (rpm)'); ylabel(aL,'Potencia efectiva (kW)'); ylabel(aR,'Par efectivo (N·m)');
        E = (Me(iM)/Me(iP))*(ns(iP)/ns(iM));
        title(aL, sprintf('Pmáx %.1f kW a %d rpm · Mmáx %.0f N·m a %d rpm · elasticidad %.2f', ...
            Pe(iP), ns(iP), Me(iM), ns(iM), E),'FontSize',8,'FontWeight','normal');
        legend(aL,[h1 h2],{'Potencia','Par'},'Location','northwest','FontSize',7);
    case 3
        a = max(0, r.ts-20); b = min(560, r.ts+r.dur+40); ii = (a:b)+1;
        xb = r.xb(ii)*100; dq = [0 diff(r.xb(ii))]; dq = dq/max(max(dq),eps)*100;
        plot(aR, a:b, dq, '-','Color',col('real'),'LineWidth',1.8);
        h1 = plot(aL, a:b, xb, '-','Color',col('pot'),'LineWidth',2);
        h2 = plot(aL, NaN, NaN, '-','Color',col('real'),'LineWidth',1.8);
        plot(aL,[360 360],[0 105],'k:');
        S.h.cur = plot(aL,[a a],[0 105],'k-'); S.h.curP = []; S.h.curT = [];
        set(aL,'XLim',[a b],'YLim',[0 105]); set(aR,'XLim',[a b],'YLim',[0 105]);
        xlabel(aL,'Ángulo del cigüeñal \theta (°) · 360° = PMS de combustión');
        ylabel(aL,'Masa quemada x_b (%)'); ylabel(aR,'dQ/d\theta (% del máximo)');
        title(aL, sprintf('Chispa %g° aPMS · duración efectiva %.0f° · calor %.0f J/cil.', in.avance, r.dur, r.Q),'FontSize',8,'FontWeight','normal');
        legend(aL,[h1 h2],{'Fracción quemada','Liberación de calor'},'Location','northwest','FontSize',7);
end
grid(aL,'on'); box(aL,'on');
pos = get(aL,'Position'); set(aR,'Position',pos);
% ---- P-V ----
cla(aP); try, legend(aP,'off'); catch, end; hold(aP,'on');
g1 = plot(aP, r.V, pU(S,r.pid), '--','Color',col('ideal'),'LineWidth',1.3);
g2 = plot(aP, [r.V r.V(1)], pU(S,[r.p r.p(1)]), '-','Color',col('real'),'LineWidth',2);
S.h.pvP = plot(aP, r.V(1), pU(S,r.p(1)), 'o','MarkerFaceColor',col('real'),'MarkerEdgeColor','k','MarkerSize',7);
set(aP,'XLim',[0 max(r.V)*1.05],'YLim',[0 pU(S,max(r.pidmax,r.pmax))*1.08]); grid(aP,'on'); box(aP,'on');
xlabel(aP,'Volumen del cilindro (cm^3)'); ylabel(aP,['Presión (' pLab(S) ')']);
title(aP, sprintf('Diagrama P-V · W = %.0f J/cil. · PMI %.2f %s', r.W, pU(S,r.pmi), pLab(S)),'FontSize',9);
legend(aP,[g2 g1],{'Real','Teórico'},'Location','northeast','FontSize',7);
setappdata(fig,'S',S);
end

% =====================================================================
%  CUADRO A CUADRO
% =====================================================================
function actualizarCuadro(fig)
S = getappdata(fig,'S'); r = S.r; in = S.in; g = geo(in); H = S.h.mot;
i = mod(round(S.theta),720); j = i + 1;
t = i*pi/180; Rk = g.Rk; D = g.D;
xc = Rk*sin(t); yc = Rk*cos(t); yb = yc + sqrt(g.lb^2 - xc^2); yTop = yb + g.pinUp; yH = g.yHead;
[nom, cg] = tiempoDe(i);
if i >= 360 && i < 540 && r.xb(j) > 0.98, cg = col('esc'); end
set(H.gas,'XData',[-D/2 D/2 D/2 -D/2],'YData',[yTop yTop yH yH],'FaceColor',mezcla(cg,0.55));
if ~r.misfire && r.xb(j) > 0.001 && r.xb(j) < 0.995 && i > r.ts && i < 560
    rad = sqrt(r.xb(j))*D*0.75; a = linspace(0,pi,40);
    xf = min(D/2, max(-D/2, rad*cos(a))); yf = max(yTop, yH - rad*sin(a));
    set(H.llama,'XData',xf,'YData',yf,'Visible','on');
else
    set(H.llama,'Visible','off');
end
cual = {'adm','esc'}; sgs = [-1 1];
for k = 1:2
    sg = sgs(k); h = alzada(S, i, cual{k})*min(10, D*0.11)*1.6; yv = yH - h; cx = sg*g.vx;
    set(H.valv(k),'XData',[cx-g.vd/2, cx+g.vd/2, cx+2, cx+2, cx-2, cx-2], ...
        'YData',[yv yv yv+6 yv+58 yv+58 yv+6]);
    yy = yv + 40 + (0:8)*(18 - h*0.2)/8; xx = cx + 6*(-1).^(1:9);
    set(H.mue(k),'XData',xx,'YData',yy);
end
if i >= r.ts && i <= r.ts + 7 && ~r.misfire
    a = (0:7)*pi/4; xs = [zeros(1,8); 9*cos(a); NaN(1,8)]; ys = [ (yH-2)*ones(1,8); yH-2+9*sin(a); NaN(1,8)];
    set(H.chispa,'XData',xs(:),'YData',ys(:),'Visible','on');
else
    set(H.chispa,'Visible','off');
end
set(H.piston,'XData',[-D/2+1 D/2-1 D/2-1 -D/2+1],'YData',[yTop-g.hp yTop-g.hp yTop yTop]);
ya = yTop - 4*(1:3);
set(H.aros,'XData',[-D/2+1 D/2-1 NaN -D/2+1 D/2-1 NaN -D/2+1 D/2-1],'YData',[ya(1) ya(1) NaN ya(2) ya(2) NaN ya(3) ya(3)]);
a0 = atan2(-yc,-xc); a = linspace(a0-0.8, a0+0.8, 30);
set(H.contra,'XData',[0 (Rk+10)*cos(a) 0],'YData',[0 (Rk+10)*sin(a) 0]);
set(H.mani,'XData',[0 xc],'YData',[0 yc]);
set(H.biela,'XData',[xc 0],'YData',[yc yb]);
set(H.pernos,'XData',[0 xc 0],'YData',[0 yc yb]);
% diagrama de fases
set(S.h.aguja,'XData',[0 1.1*sind(i)],'YData',[0 1.1*cosd(i)]);
set(S.h.centro,'String',nom(4:end),'Color',cg*0.85);
if i < 360, set(S.h.vuelta,'String','vuelta 1 de 2'); else, set(S.h.vuelta,'String','vuelta 2 de 2'); end
set(S.h.tiempo,'String',nom,'ForegroundColor',cg*0.85);
set(S.h.angTxt,'String',sprintf('Ángulo del cigüeñal: %d°',i));
set(S.h.ang,'Value',i);
% gráficas
if ~isempty(S.h.cur) && ishandle(S.h.cur), set(S.h.cur,'XData',[i i]); end
if ~isempty(S.h.curP) && ishandle(S.h.curP), set(S.h.curP,'XData',i,'YData',pU(S,r.p(j))); end
if ~isempty(S.h.curT) && ishandle(S.h.curT), set(S.h.curT,'XData',i,'YData',r.T(j)-273.15); end
set(S.h.pvP,'XData',r.V(j),'YData',pU(S,r.p(j)));
% resultados
S.lineas = textoResultados(S, i);
set(S.h.res,'String',S.lineas);
setappdata(fig,'S',S);
end

function L = textoResultados(S, i)
r = S.r; in = S.in; C = combustibles(); j = i + 1; u = pLab(S); u = strrep(u,'^2','²');
kn = r.knock;
if kn < 0.9, sk = 'bajo'; elseif kn < 1.0, sk = 'moderado'; else, sk = 'ALTO'; end
if in.lambda < 0.97, mz = 'rica'; elseif in.lambda > 1.03, mz = 'pobre'; else, mz = 'estequiométrica'; end
dp = r.thmax - 360;
if dp < 8, ae = 'adelantado'; elseif dp > 17, ae = 'retrasado'; else, ae = 'cercano al óptimo'; end
va = 'cerrada'; ve = 'cerrada';
ha = alzada(S,i,'adm'); he = alzada(S,i,'esc');
if ha > 0.02, va = sprintf('abierta %.0f %%', ha*100); end
if he > 0.02, ve = sprintf('abierta %.0f %%', he*100); end
L = { sprintf('RESULTADOS POR CICLO  (%s)', C(in.fuel).nombre)
      '------------------------------------------'
      sprintf('Cilindrada total     %8.2f L  (Vu %.1f cm³)', r.Vt/1000, r.Vu)
      sprintf('Cámara Vcc           %8.1f cm³', r.Vc)
      sprintf('Presión máxima       %8.1f %s a %d° dPMS', pU(S,r.pmax), u, dp)
      sprintf('Temperatura máxima   %8.0f °C (teórica %.0f)', r.Tmax-273.15, r.Tidmax-273.15)
      sprintf('PMI                  %8.2f %s', pU(S,r.pmi), u)
      sprintf('PME                  %8.2f %s (pérd. %.2f)', pU(S,r.pme), u, pU(S,r.pmf))
      sprintf('Potencia efectiva    %8.1f kW = %.0f CV', r.Pe/1000, r.Pe/735.5)
      sprintf('Par efectivo         %8.0f N·m (ind. %.0f)', r.Me, r.Mi)
      sprintf('Rend. efectivo       %8.1f %% (Otto %.1f %%)', r.etae*100, r.etaid*100)
      sprintf('Consumo específico   %8.0f g/kWh', r.ge)
      sprintf('Consumo horario      %8.1f kg/h', r.fuelH)
      sprintf('Rend. volumétrico    %8.0f %% (adm. %.1f kPa)', r.etaV*100, r.Padm)
      sprintf('Vel. media pistón    %8.1f m/s (r/l = %.2f)', r.vm, r.lam)
      ''
      'INDICADORES'
      '------------------------------------------'
      sprintf('Riesgo de detonación: %s (%.2f)', sk, kn)
      sprintf('Mezcla %s (lambda = %.2f)', mz, in.lambda)
      sprintf('Encendido %s', ae) };
if r.misfire, L{end+1} = 'FALLO DE ENCENDIDO: mezcla fuera de límites'; end
if r.Pe <= 0, L{end+1} = 'Sin potencia neta con estos datos'; end
L = [L; { ''; sprintf('INSTANTE  theta = %d°', i); '------------------------------------------'
      sprintf('Posición del pistón  %8.1f mm', (r.V(j)-r.Vc)/r.Sp*10)
      sprintf('Volumen              %8.1f cm³', r.V(j))
      sprintf('Presión real         %8.2f %s', pU(S,r.p(j)), u)
      sprintf('Presión teórica      %8.2f %s', pU(S,r.pid(j)), u)
      sprintf('Temperatura real     %8.0f °C', r.T(j)-273.15)
      sprintf('Masa quemada         %8.0f %%', r.xb(j)*100)
      sprintf('Válvula admisión     %s', va)
      sprintf('Válvula escape       %s', ve) }];
end
