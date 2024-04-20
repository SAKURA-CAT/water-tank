% 水箱的数学模型函数：
function y=func( h,u )
ki = 0.306;
ko = 0.212;
y = (-ko*sqrt(h)+ki*u)/(3.1415926*(1+2*sqrt(3)*h/3+(h^2)/3));
end
% 主程序：
%定义模糊控制器
a=newfis('Water Tank');
%定义高度误差e的隶属度函数
a=addvar(a,'input','e',[-1 1]);
a=addmf(a,'input',1,'N','trapmf',[-1,-1,-0.8,0]);
a=addmf(a,'input',1,'ZR','trimf' ,[-0.8,0,0.8]);
a=addmf(a,'input',1,'P','trapmf',[0,0.8,1,1]);
%定义高度误差变化率de的隶属度函数
a=addvar(a,'input','de',[-1 1]);
a=addmf(a,'input',2,'N','trapmf' ,[-1,-1,-0.8,0]);
a=addmf(a,'input',2,'ZR','trimf' ,[-0.8,0,0.8]);
a=addmf(a,'input',2,'B','trapmf' ,[0,0.8,1,1]);
%定义输出变量（入水阀门开关度）u的隶属度函数
a=addvar(a,'output','u',[-5 5]);
a=addmf(a,'output',1,'NB','trapmf',[-5,-5,-4,-2]);
a=addmf(a,'output',1,'NS','trimf',[-4,-2,0]);
a=addmf(a,'output',1,'ZR','trimf',[-2,0,2]);
a=addmf(a,'output',1,'PS','trimf',[0,2,4]);
a=addmf(a,'output',1,'PB','trapmf',[2,4,5,5]);

% 绘制定义的隶属度函数
figure(1);

% 绘制水位差e的隶属度函数
subplot(2,1,1);
plotmf(wt, 'input', 1); % 绘制水位差e的隶属度函数

% 设置图标题和坐标轴标签
title('水位差e的隶属度函数');
xlabel('水位差e');
ylabel('隶属度');

% 绘制水位变化率de的隶属度函数
subplot(2,1,2);
plotmf(wt, 'input', 2); % 绘制水位变化率de的隶属度函数

% 设置图标题和坐标轴标签
title('水位变化率de的隶属度函数');
xlabel('水位变化率de');
ylabel('隶属度');


%定义模糊规则
rulelist = [1 0 5 1 2;2 1 4 1 1;2 2 3 1 1;2 3 2 1 1;3 0 1 1 2];
a=addrule(a,rulelist);

%定义采样时间间隔
T=1;
%定义总采样点数
N=2500;

% 初始高度
h = 10;
%预想达到的液面高度
hd1 = 5;

e = h - hd1;    %计算初始时刻的液面误差
de = 0;         %设定初始时刻液面误差变化率为0
%误差变化率的系数，以求得模糊推理中论域内的误差变化率
%针对de，其余两个参数设置为1
kd = 5.9;
%定义水箱进水口阀门的绝对开关量
u1 = 0;

% 保存采样集合
hd = zeros(1, N);  % 理想页面高度
yy = zeros(1, N);  % 实际高度
ed = zeros(1, N);  % 高度差e
dd = zeros(1, N);  % 高度差变化率de
uu = zeros(1, N);  % 阀门开启度


% 开始采样
for k = 1:N
    hd(1,k) = hd1;

    %求得论域内的误差变化率
    de1 = kd*de;
    if e>=1
            e=1;
    elseif e<=-1
            e=-1;
    end
    if de1>=1
            de1=1;
    end
    %输入模糊控制器的参数
    in = [e de1];
    ed(1, k) = e;
    dd(1, k) = de1;

    %得出模糊控制器的输出结果（进水阀门开启或关闭的变化量
    u = evalfis(in,a);
    u1 = u1+u;  %得到阀门此时的绝对开启量
    %判断此时阀门绝对开启量与最大开启量的关系
    if u1>=5
        u1=5;
    elseif u1<=0
        u1=0;
    end

    uu(1,k)=u1; %将每一采样点时刻的绝对开启量存入一数组uu
    %阀门绝对开启度作用于控制对象
    k1 = func(h,u1);
    k2 = func(h+T*k1/2,u1);
    k3 = func(h+T*k2/2,u1);
    k4 = func(h+T*k3,u1);
    h = h+(k1+2*k2+2*k3+k4)*T/6;    %用龙格库塔法求出每一采样时刻的液面高度
    yy(1,k)=h;     %将每一采样时刻液面高度存入数组yy
    e1 = e;        %将误差赋给新变量e1
    e = h-hd(1,k); %求得新的误差
    de = (e-e1)/T; %得出新的误差变化率
end

% 页面高度变化
figure(2);
plot(1:N,hd,'k',1:N, yy,'r');
grid on
xlabel('时间（秒）');
ylabel('液面高度');

% 阀门开启量变化
figure(3);
plot(1:N,uu,'b');
grid on
xlabel('时间（秒）');
ylabel('输入阀门开关度');

% 创建一个新的图形窗口，并设置两个子图的位置
figure(4);

% 绘制输入e的变化曲线
subplot(2,1,1);
plot(1:N, ed, 'b');
xlabel('时间（秒）');
ylabel('e输入变化曲线');

% 绘制输入de的变化曲线
subplot(2,1,2);
plot(1:N, dd, 'b');
xlabel('时间（秒）');
ylabel('de输入变化曲线');
