function Sim_CicloReal_Wiebe(varargin)
% SIM_CICLOREAL_WIEBE  Ciclo real de un motor Otto calculado grado a grado.
%
%   Introducción a Motores (MA.01.04) - ISTS · Unidades 2 y 4
%   (2.4.3 Ciclo Otto real · 4.3 PME y rendimiento · 4.5 Funcionamiento)
%
%   Modelo de una zona: en cada grado del cigüeñal se aplica la primera ley
%   al gas encerrado en el cilindro,
%
%        dp = [ (k-1)·dQ  -  k·p·dV ] / V
%
%   donde dV sale del mecanismo biela-manivela y dQ de la ley de Wiebe,
%   que reparte el calor del combustible a lo largo de la combustión:
%
%        xb(θ) = 1 - exp( -a·((θ - θi)/Δθ)^(m+1) )
%
%   La admisión y el escape se representan a presión constante (lazo de
%   bombeo). Se compara con el ciclo Otto ideal que recibe el mismo calor.
%
%   Uso: Sim_CicloReal_Wiebe   y mueva los deslizadores.
%   Compatible con MATLAB (R2014b o superior, sin toolboxes) y GNU Octave.

%% ---------------- DATOS FIJOS DEL MOTOR (modifique aquí) ----------------
e.D   = 84;    e.L = 81;   e.lb = 135;   % mm (motor de la guía, Unidad 4)
e.k   = 1.32;                            % relación de calores de la mezcla
e.T1  = 330;                             % K, temperatura al cierre de la admisión
e.AF  = 14.7;                            % relación aire/combustible estequiométrica
e.PCI = 44e6;                            % J/kg, gasolina
e.RCA = 40;  e.AAE = 45;                 % cotas de distribución, °
e.Pesc = 1.10;                           % bar, contrapresión de escape
e.a = 5; e.m = 2;                        % parámetros de Wiebe
% valores iniciales de los deslizadores
v0 = struct('avance',25,'dur',50,'Rc',9.9,'Padm',0.95,'eta',0.75);

%% ---------------- INTERFAZ ----------------
fig = figure('Name','Ciclo real con ley de Wiebe - Introducción a Motores (ISTS)', ...
    'NumberTitle','off','Color','w','Units','normalized','Position',[0.04 0.06 0.92 0.86]);
ax(1) = axes('Parent',fig,'Position',[0.05 0.56 0.40 0.38]);
ax(2) = axes('Parent',fig,'Position',[0.53 0.56 0.40 0.38]);
ax(3) = axes('Parent',fig,'Position',[0.05 0.08 0.40 0.36]);
info = uicontrol(fig,'Style','text','Units','normalized','Position',[0.53 0.24 0.42 0.20], ...
    'BackgroundColor',[0.95 0.97 0.97],'HorizontalAlignment','left','FontSize',10,'FontName','Arial');
def = {'avance','Avance del encendido (° antes del PMS)',0,50; ...
       'dur','Duración de la combustión (°)',20,100; ...
       'Rc','Relación de compresión Rc',6,14; ...
       'Padm','Presión de admisión (bar) — Loja WOT ≈ 0,75',0.3,2.0; ...
       'eta','Fracción útil del calor (combustión y pérdidas)',0.5,1.0};
sl = zeros(1,size(def,1)); lb = sl;
for i = 1:size(def,1)
    y = 0.19 - (i-1)*0.037;
    lb(i) = uicontrol(fig,'Style','text','Units','normalized','Position',[0.53 y 0.25 0.03], ...
        'BackgroundColor','w','HorizontalAlignment','left','FontSize',9);
    sl(i) = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.79 y+0.005 0.16 0.025], ...
        'Min',def{i,3},'Max',def{i,4},'Value',v0.(def{i,1}),'Callback',@(s,ev) redibujar());
end

redibujar();
if nargin > 0 && strcmp(varargin{1},'captura')
    drawnow; disp(get(info,'String')); print(fig,'captura_wiebe_base.png','-dpng','-r80');
    set(sl(1),'Value',5); redibujar(); drawnow; print(fig,'captura_wiebe_avance5.png','-dpng','-r80');
    close(fig);
end

    function redibujar()
        v = struct();
        for j = 1:size(def,1)
            v.(def{j,1}) = get(sl(j),'Value');
            set(lb(j),'String',sprintf('%s:  %.2f', def{j,2}, v.(def{j,1})));
        end
        r = calcula(e, v);
        % --- P-theta
        cla(ax(1)); hold(ax(1),'on'); grid(ax(1),'on'); box(ax(1),'on');
        plot(ax(1), r.th, r.p, 'Color',[0.89 0.34 0.18],'LineWidth',1.8);
        plot(ax(1), r.th, r.pmot, '--','Color',[0.35 0.40 0.44],'LineWidth',1.2);
        plot(ax(1), [r.ts r.ts], [0 max(r.p)*1.05], ':','Color',[0.05 0.49 0.48],'LineWidth',1.4);
        plot(ax(1), r.thmax, max(r.p), 'o','MarkerFaceColor',[0.08 0.14 0.25],'MarkerEdgeColor','w','MarkerSize',8);
        xlim(ax(1),[180 540]); set(ax(1),'XTick',180:30:540);
        xlabel(ax(1),'Ángulo del cigüeñal \theta (°)  (360° = PMS de combustión)'); ylabel(ax(1),'Presión (bar)');
        title(ax(1),'Presión en el cilindro');
        legend(ax(1),{'Con combustión','Arrastre (sin combustión)','Salto de chispa','Presión máxima'},'Location','northeast');
        % --- P-V
        cla(ax(2)); hold(ax(2),'on'); grid(ax(2),'on'); box(ax(2),'on');
        plot(ax(2), r.Vid, r.pid, '--','Color',[0.35 0.40 0.44],'LineWidth',1.3);
        plot(ax(2), r.V, r.p, 'Color',[0.89 0.34 0.18],'LineWidth',1.8);
        xlabel(ax(2),'Volumen del cilindro (cm^3)'); ylabel(ax(2),'Presión (bar)');
        title(ax(2),'Diagrama P-V: ciclo real frente al ciclo Otto ideal');
        legend(ax(2),{'Otto ideal (mismo calor)','Ciclo real'},'Location','northeast');
        % --- fracción quemada y liberación de calor
        cla(ax(3)); hold(ax(3),'on'); grid(ax(3),'on'); box(ax(3),'on');
        plot(ax(3), r.th, r.xb*100, 'Color',[0.05 0.49 0.48],'LineWidth',1.8);
        plot(ax(3), r.th, r.dQ/max(r.dQ)*100, 'Color',[0.89 0.34 0.18],'LineWidth',1.4);
        plot(ax(3), [360 360],[0 105],'k:');
        xlim(ax(3),[r.ts-20, r.ts+v.dur+30]); ylim(ax(3),[0 105]);
        xlabel(ax(3),'Ángulo del cigüeñal \theta (°)'); ylabel(ax(3),'%');
        title(ax(3),'Ley de Wiebe: fracción quemada y liberación de calor');
        legend(ax(3),{'Fracción de masa quemada x_b (%)','Liberación de calor dQ/d\theta (% del máximo)'},'Location','east');
        % --- resultados
        set(info,'String',{ ...
            sprintf('Cilindrada unitaria Vu = %.1f cm³   ·   Vcc = %.1f cm³', r.Vu, r.Vcc), ...
            sprintf('Masa de aire = %.0f mg  ·  combustible = %.1f mg  ·  calor útil = %.0f J', r.mair*1e6, r.mf*1e6, r.Q), ...
            sprintf('Presión máxima = %.1f bar a %.0f° (%.0f° después del PMS)', max(r.p), r.thmax, r.thmax-360), ...
            sprintf('Trabajo indicado = %.0f J/ciclo  ·  PMI = %.2f bar', r.W, r.pmi), ...
            sprintf('Rendimiento indicado = %.1f %%  ·  Otto ideal = %.1f %%', r.etai*100, r.etaid*100), ...
            sprintf('Potencia indicada a 3 000 rpm (4 cil.) = %.1f kW', r.W*4*3000/120/1000), ...
            'Sugerencia: busque el avance que da la mayor PMI (avance óptimo).'});
        drawnow;
    end
end

%% =====================================================================
function r = calcula(e, v)
th = (0:0.5:720)';
rr = e.L/2; lam = rr/e.lb;
Sp = pi*(e.D/10)^2/4; Vu = Sp*e.L/10; Vcc = Vu/(v.Rc-1);
t = th*pi/180;
x = rr*((1-cos(t)) + (1/lam)*(1 - sqrt(1 - lam^2*sin(t).^2)));
V = Vcc + Sp*x/10;                                  % cm^3
IVC = 180 + e.RCA; EVO = 540 - e.AAE; ts = 360 - v.avance;
iI = find(th >= IVC,1); iE = find(th >= EVO,1);
R = 287;
mair = v.Padm*1e5*V(iI)*1e-6/(R*e.T1); mf = mair/e.AF; Q = mf*e.PCI*v.eta;
xb = 1 - exp(-e.a*max((th - ts)/v.dur,0).^(e.m+1));
p = zeros(size(th)); pm = p;
p(1:iI) = v.Padm; p(iE:end) = e.Pesc; pm(1:iI) = v.Padm; pm(iE:end) = e.Pesc;
for i = iI:iE-1
    dV = (V(i+1)-V(i))*1e-6; Vi = 0.5*(V(i)+V(i+1))*1e-6;
    dQ = Q*(xb(i+1)-xb(i));
    p(i+1)  = p(i)  + ((e.k-1)*dQ - e.k*p(i)*1e5*dV)/Vi/1e5;
    pm(i+1) = pm(i) + (-e.k*pm(i)*1e5*dV)/Vi/1e5;
end
dQth = [0; diff(xb)]*Q/0.5;                         % J/°
% trabajo del ciclo completo (incluye bombeo)
W = sum(0.5*(p(1:end-1)+p(2:end))*1e5 .* diff(V)*1e-6);   % J, integral de p·dV en el ciclo
pmi = W/(Vu*1e-6)/1e5;
[~, im] = max(p);
% Otto ideal con el mismo calor (desde el estado al cierre de la admisión)
V1 = Vu+Vcc; V2 = Vcc; p1 = v.Padm; T1 = e.T1; cv = R/(e.k-1);
p2 = p1*(V1/V2)^e.k; T2 = T1*(V1/V2)^(e.k-1);
T3 = T2 + Q/(mair*cv); p3 = p2*T3/T2; p4 = p3*(V2/V1)^e.k;
Vc = linspace(V1,V2,60)'; Ve = linspace(V2,V1,60)';
Vid = [Vc; V2; Ve; V1]; pid = [p1*(V1./Vc).^e.k; p3; p3*(V2./Ve).^e.k; p1];
etaid = 1 - 1/(V1/V2)^(e.k-1);
r = struct('th',th,'V',V,'p',p,'pmot',pm,'xb',xb,'dQ',dQth,'ts',ts,'thmax',th(im), ...
    'W',W,'pmi',pmi,'etai',W/(mf*e.PCI),'etaid',etaid,'Vu',Vu,'Vcc',Vcc,'mair',mair,'mf',mf,'Q',Q, ...
    'Vid',Vid,'pid',pid);
end
