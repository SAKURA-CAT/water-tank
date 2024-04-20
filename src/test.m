function y = fu(h, u)
  ko = 0.5;
  ki = 0.067;
  y = (-ko*h + ki*u) / (3.1415926*(1 + 2*sqrt(3)*h/3 + (h^2)/3));
end


%定义模糊控制器
a = newfis('Water Tank');
%定义高度误差e的隶属度函数
a=addvar(a,'input','e',[-2 2]);
a = addmf(a, 'input', 1, 'N', 'trimf', [-3, -2, 0]);
a = addmf(a, 'input', 1, 'ZO', 'trimf', [-1.5, 0, 1.5]);
a = addmf(a, 'input', 1, 'P', 'trimf', [0, 2, 3]);
%定义高度误差变化率de的隶属度函数
a=addvar(a,'input','de',[-2 2]);
a = addmf(a, 'input', 2, 'N', 'trimf', [-3, -2, 0]);
a = addmf(a, 'input', 2, 'ZO', 'trimf', [-1.5, 0, 1.5]);
a = addmf(a, 'input', 2, 'P', 'trimf', [0, 2, 3]);
%定义输出变量（入水阀门开关度）u的隶属度函数
a = addvar(a, 'output', 'u', [-2 2]);
a = addmf(a, 'output', 1, 'NB', 'trimf', [-3, -2,-1]);
a = addmf(a, 'output', 1, 'NS', 'trimf', [-2, -1, 0]);
a = addmf(a, 'output', 1, 'ZO', 'trimf', [-1, 0, 1]);
a = addmf(a, 'output', 1, 'PS', 'trimf', [0, 1, 2]);
a = addmf(a, 'output', 1, 'PB', 'trimf', [1, 2, 3]);

%定义模糊规则
rulelist = [
    1 0 5 1 2;
    2 1 4 1 1;
    2 2 3 1 1;
    2 3 2 1 1;
    3 0 1 1 2
];
a=addrule(a,rulelist);
showrule(a)


% 绘制定义的隶属度函数
figure(1);

% 绘制水位差e的隶属度函数
subplot(3, 1, 1);
plotmf(a, 'input', 1);
ylabel('隶属度函数');
xlabel('水位差e');

% 绘制水位变化率de的隶属度函数
subplot(3, 1, 2);
plotmf(a, 'input', 2);
ylabel('隶属度函数');
xlabel('水位变化率de');

% 绘制阀门变量u的隶属度函数
subplot(3, 1, 3);
plotmf(a, 'output', 1);
ylabel('隶属度函数');
xlabel('阀门开度u');



T = 1;          %定义采样时间间隔
N = 1000;        %定义总采样点数
h0 = 5;        %预计达到的高度
h = 10;          %初始高度
e = h - h0;     %计算初始时刻的液面误差
de = 0;         %设定初始时刻液面误差变化率为0
u1 = 0;         %定义水箱进水口阀门的绝对开关量
% 映射系数
ke = 0.1;
kd = 1.2;

% 将u从论域中映射回真实角度
ku = 45;

% 保存采样集合
h00 = zeros(1, N);  %理想高度
hh  = zeros(1, N);  %实际高度
ee  = zeros(1, N);  %高度差e
dee = zeros(1, N);  %高度差变化率de
uu  = zeros(1, N);  %阀门开启度变化率
u11 = zeros(1, N);  %阀门绝对开启度[0,90]

%将模糊控制器作用于被控对象
for k = 1:N
  %理想液面高度
  h00(1, k) = h0;

  e1 = ke*e;
  de1 = kd*de;
  if e1 >= 2
    e1 = 2;
  elseif e1 <=-2
    e1 = -2;
  end
  % 记录到集合
  ee(1, k) = e1;
  dee(1, k) = de1;

  in = [e1 de1];
  u = evalfis(in, a);  %得出模糊控制器的输出结果（进水阀门开启或关闭的变化量）
  if u >= 2
     u = 2;
  elseif u <= -2
     u = -2;
  end

  uu(1, k) = u;
  %阀门绝对开启量，题目限制为0到90度
  u1 = ku * u + u1;

  if u1 >=90
      u1=90;
  elseif u1<=0
      u1=0;
  end

  u11(1, k) = u1;

  %用龙格库塔法求出每一采样时刻的液面高度
  k1 = fu(h, u1);
  k2 = fu(h + T*k1/2, u1);
  k3 = fu(h + T*k2/2, u1);
  k4 = fu(h + T*k3, u1);
  h = h + (k1 + 2*k2 + 2*k3 + k4) * T/6;
  hh(1, k) = h;      %将每一采样时刻液面高度存入数组hh

  e2 = e;            %将误差赋给e2
  e = h - h0;        %求得新的误差
  de = (e - e2) / T; %得出新的误差变化率
end

%将每一采样时刻构成的时间序列作为一时间轴
kk = 1:N;

%画出预想的液面高度，以及实际液面高度随时间的变化
figure(2);
plot(kk, hh, 'k', kk, h00, 'r');
grid on
xlabel('时间（秒）');
ylabel('液面高度');
legend('实际高度', '预期高度')

%画出进水阀门的绝对开启量随时间的变化
figure(3);
plot(kk, uu, 'b');
grid on
xlabel('时间（秒）');
ylabel('模糊控制器输出曲线');

% 创建一个新的图形窗口，并设置两个子图的位置
figure(4);
% 绘制输入e的变化曲线
subplot(2, 1, 1);
plot(kk, ee, 'b');
xlabel('时间（秒）');
ylabel('e输入变化曲线');

% 绘制输入de的变化曲线
subplot(2, 1, 2);
plot(kk, dee, 'b');
xlabel('时间（秒）');
ylabel('de输入变化曲线');

%画出进水阀门的绝对开启量随时间的变化
figure(5);
plot(kk, u11, 'b');
grid on
xlabel('时间（秒）');
ylabel('输入阀门绝对开关度');
