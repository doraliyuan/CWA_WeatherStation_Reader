% Program: read_cwbdata.m
% Target: Auto get the CWB station rain data nearby the epicenter 30days
%         before the earthquake happened.
%
% Input file: cases list or input parameters manually
% Output file: yyyymmdd_Mxx_Dxx.mat
%
% Author: Li-Yuan,Wang
% Date: 2023.04.28

clear all
close all
clc

% 輸入檔案(氣象測站資料)的資料夾路徑
dir = 'C:\Users\USER\Desktop\112CWB_project\cwb_station_data\';
% 輸入檔案(地震清單)的資料夾路徑
dir0 = 'C:\Users\USER\Desktop\112CWB_project\';
% 輸出檔案的資料夾路徑
diro = 'C:\Users\USER\Desktop\112CWB_project\atm_abnormal\obs\mat\before_after_31days\';

% 讀取氣象局測站位置
fn1 = 'cwb_stations_manual_20230419.csv';
table = readtable([dir fn1], 'PreserveVariableNames', true);
stas = string(table2array(table(:,1)));
stas_lon = table2array(table(:,5));
stas_lat = table2array(table(:,6));
stas_alt = table2array(table(:,4));
%scatter(stas_lon, stas_lat);

% 讀取地震清單
%fn0 = '1994_2022_m5_eqlist_afsh_lt.txt';
fn0 = '112CWB_EQlist_class_new.txt';
fid0 = fopen([dir0 fn0]);
%eqlist = textscan(fid0, repmat('%s',[1,10]));
eqlist = textscan(fid0, repmat('%s',[1,14]));
years = eqlist{1,1};
nz0 = size(years);

% 批次處理地震清單
for i = 1:nz0
    year = str2double(eqlist{1,1}{i,1});
    month = str2double(eqlist{1,2}{i,1});
    day = str2double(eqlist{1,3}{i,1});
    hour = str2double(eqlist{1,4}{i,1});
    minute = str2double(eqlist{1,5}{i,1});
    second = str2double(eqlist{1,6}{i,1});
    lon = str2double(eqlist{1,7}{i,1});
    lat = str2double(eqlist{1,8}{i,1});
    depth = str2double(eqlist{1,9}{i,1});
    mo = str2double(eqlist{1,10}{i,1});
    disp([num2str(year) ' ' num2str(month) ' ' num2str(day) ' ' num2str(hour) ' ' num2str(minute) ' ' num2str(second) ' ' ...
        num2str(lon) ' ' num2str(lat) ' ' num2str(depth) ' ' num2str(mo)])
    
    % 參數型態格式化，輸出檔案之檔名用。 Ex: 2 --> 02; 6.5 --> 07
    month0 = sprintf('%02d', month);
    day0 = sprintf('%02d', day);
    hour0 = sprintf('%02d', hour);
    minute0 = sprintf('%02d', minute);
    second0 = sprintf('%02.0f', second);
    
    % 找距離震央最近的測站
    arclen = distance('gc', [lat,lon], [stas_lat,stas_lon]);
    arclen2 = sort(arclen);
    stas_near = string([]);
    stas_near_lat = [];
    stas_near_lon = [];
    stas_near_alt = [];
    
    j = 0;
    sz = size(stas);
    for i = 1:sz(1)
        %disp(i)
        k = i+j;
        %disp(k)
        if k(1) > sz(1)
            break
        end
        z = find(arclen2(k(1)) == arclen);
        n = size(z);
        
        stas_near(k:k+n-1) = stas(z);
        stas_near_lon(k:k+n-1) = stas_lon(z);
        stas_near_lat(k:k+n-1) = stas_lat(z);
        stas_near_alt(k:k+n-1) = stas_alt(z);
        if n(1) > 1
            j = j+n-1;
        end
    end
    
    % 自動判別地震發生前30天的日期，並一天一天抓取指定資料
    if mod(year,4) == 0
        sdt=[1 32 61 92 122 153 183 214 245 275 306 336];
        edoy = 366;
    else
        sdt=[1 32 60 91 121 152 182 213 244 274 305 335];
        edoy = 365;
    end
    doy = sdt(1,month)+day-1;
    
    shiftday = 0;
    doy1 = doy-15+shiftday;
    doy2 = doy+15+shiftday;
    
    nn = 4;                                                                             % 總共要找幾個測站
    ns = 1;
    rain_f_all = string(NaN(744,nn));
    ps_f_all = string(NaN(744,nn));
    tp_f_all = string(NaN(744,nn));
    rh_f_all = string(NaN(744,nn));
    station_stno_all = string(NaN(1,nn));
    station_lat_all = NaN(1,nn);
    station_lon_all = NaN(1,nn);
    station_alt_all = NaN(1,nn);
    station_dist_all = NaN(1,nn);
    
    sz2 = size(stas_near);
    for s = 1:sz2(2)
        disp(stas_near(s))
        
        yyyymmdd = string([]);
        rain_f = [];
        ps_f = [];
        tp_f = [];
        rh_f = [];
        x = 1;
        for doys = doy1:doy2
            year2 = year;
            doys2 = doys;
            if doys <= 0
                year2 = year-1;
                if mod(year2,4) == 0
                    edoy2 = 366;
                else
                    edoy2 = 365;
                end
                doys2 = doys+edoy2;
            end
            if doys > edoy
                doys2 = doys-edoy;
                year2 = year+1;
            end
            yyyymmdd_tmp = datetime(year2,1,1)+days(doys2)-1;
            yyyymmdd(x) = datetime(yyyymmdd_tmp, 'Format','yyyyMMdd');
            %disp(yyyymmdd(x))
            yyyymmdd_c = char(yyyymmdd(x));
            yyyymm = yyyymmdd_c(1:6);
            
            station = char(stas_near(s));
            fn = [];
            if station(1) == 'C'
                fn = [yyyymm '_auto_hr.txt'];
            elseif station(1) == '4'
                fn = [yyyymm '_cwb_hr.txt'];
            else
                disp('No data')
                break
            end
            fid = fopen([dir fn]);
            
            n = 0;
            while ~feof(fid)                                                            % 一行一行讀(直到檔尾)。
                tline = fgetl(fid);                                                     % 此行的資料
                n = n+1;                                                                % 紀錄讀到第幾行
                if tline(1)=='#'                                                        % 如果行的開頭是井字號，
                    head = strsplit(tline);                                             % 獲取資料標頭
                    nhead = size(head);                                                 % 計算有幾個資料標頭
                    %data = textscan(fid, ['%s %s',repmat('%f',[1,nhead(2)-3])]);        % 一口氣讀取此行以下所有資料，並跳出迴圈。資料格式寫法要注意。
                    data = textscan(fid, ['%s %s',repmat('%s',[1,nhead(2)-3])]);        % 一口氣讀取此行以下所有資料，並跳出迴圈。資料格式寫法要注意。
                    break
                end
            end
            m1 = find(string(head)=='stno')-1;                                          % 判別站碼為第幾欄
            m2 = find(string(head)=='yyyymmddhh')-1;                                    % 判別時間為第幾欄
            m3 = find(string(head)=='PP01')-1;                                          % 判別雨量為第幾欄
            m4 = find(string(head)=='PS01')-1;                                          % 判別氣壓為第幾欄
            m5 = find(string(head)=='TX01')-1;                                          % 判別氣溫為第幾欄
            m6 = find(string(head)=='RH01')-1;                                          % 判別相對溼度為第幾欄
            stno = string(data{1,m1});                                                  % 此檔案的站碼資料
            time = string(data{1,m2});                                                  % 此檔案的時間資料
            rain = data{1,m3};                                                          % 此檔案的雨量資料
            ps = data{1,m4};                                                            % 此檔案的氣壓資料
            tp = data{1,m5};                                                            % 此檔案的溫度資料
            rh = data{1,m6};                                                            % 此檔案的相對溼度資料
            
            yyyy = str2num(yyyymmdd_c(1:4));
            mm = str2num(yyyymmdd_c(5:6));
            dd = str2num(yyyymmdd_c(7:8));
            eom = eomday(yyyy,mm);
            if dd == eom
                yyyymmdd2_c = char(datetime(yyyymmdd_c,'Format','yyyyMMdd')+days(1));
                yyyymm2 = yyyymmdd2_c(1:6);
                
                fn2 = [];
                if station(1) == 'C'
                    fn2 = [yyyymm2 '_auto_hr.txt'];
                elseif station(1) == '4'
                    fn2 = [yyyymm2 '_cwb_hr.txt'];
                else
                    disp('No data')
                    break
                end
                %disp(fn2)
                fid2 = fopen([dir fn2]);
                
                m = 0;
                while ~feof(fid2)                                                       % 一行一行讀(直到檔尾)。
                    tline2 = fgetl(fid2);                                               % 此行的資料
                    m = m+1;                                                            % 紀錄讀到第幾行
                    if tline2(1)=='#'                                                   % 如果行的開頭是井字號，
                        head2 = strsplit(tline2);                                       % 獲取資料標頭
                        nhead2 = size(head2);                                           % 計算有幾個資料標頭
                        data2 = textscan(fid2, ['%s %s',repmat('%s',[1,nhead2(2)-3])]); % 一口氣讀取此行以下所有資料，並跳出迴圈。資料格式寫法要注意。
                        break
                    end
                end
                m12 = find(string(head2)=='stno')-1;                                    % 判別站碼為第幾欄
                m22 = find(string(head2)=='yyyymmddhh')-1;                              % 判別時間為第幾欄
                m32 = find(string(head2)=='PP01')-1;                                    % 判別雨量為第幾欄
                m42 = find(string(head2)=='PS01')-1;                                    % 判別氣壓為第幾欄
                m52 = find(string(head2)=='TX01')-1;                                    % 判別氣溫為第幾欄
                m62 = find(string(head2)=='RH01')-1;                                    % 判別相對溼度為第幾欄
                stno2 = string(data2{1,m12});                                           % 此檔案的站碼資料
                time2 = string(data2{1,m22});                                           % 此檔案的時間資料
                rain2 = data2{1,m32};                                                   % 此檔案的雨量資料
                ps2 = data2{1,m42};                                                     % 此檔案的氣壓資料
                tp2 = data2{1,m52};                                                     % 此檔案的溫度資料
                rh2 = data2{1,m62};                                                     % 此檔案的相對溼度資料
                
                stno = [stno; stno2];
                time = [time; time2];
                rain = [rain; rain2];
                ps = [ps; ps2];
                tp = [tp; tp2];
                rh = [rh; rh2];
                
                fclose(fid2);
            end
            
            for h_ut = 1:24                                                             % 一個小時一個小時去找所要的資料
                h = h_ut+8;                                                             % local time
                if h > 24
                    h = h-24;
                    hh = sprintf('%02d',h);
                else
                    hh = sprintf('%02d',h);
                end
                if h == 24
                    yyyymmdd_c = char(datetime(yyyymmdd_c,'Format','yyyyMMdd')+days(1));
                end
                
                f1 = find(stno==stas_near(s) & time==[yyyymmdd_c hh]);                  % 假設尋找測站為stas_near(s)，且時間點為yyyymmddhh的資料
                if isempty(f1)
                    disp('No data')
                    break
                end
                rain_f = [rain_f; rain(f1)];
                ps_f = [ps_f; ps(f1)];
                tp_f = [tp_f; tp(f1)];
                rh_f = [rh_f; rh(f1)];
            end
            fclose(fid);
            
            if isempty(f1)
                break
            end
            x = x+1;
        end
        if isempty(fn)
            continue
        end
        if isempty(fn2)
            continue
        end
        if isempty(f1)
            continue
        end
        rain_f_all(:,ns) = rain_f;
        ps_f_all(:,ns) = ps_f;
        tp_f_all(:,ns) = tp_f;
        rh_f_all(:,ns) = rh_f;      
        station_stno_all(:,ns) = stas_near(s);
        station_lon_all(:,ns) = stas_near_lon(s);
        station_lat_all(:,ns) = stas_near_lat(s);
        station_alt_all(:,ns) = stas_near_alt(s);
        station_dist_all(:,ns) = arclen2(s);
        
        ns = ns+1;
        %disp(ns)
        if ns > nn                                                                      % 總共要找幾個測站
            break
        end
    end
    
    % 特殊值(-9999、-9998、-9997、-9997、-9996、-9991)給予無效值NaN
    rain_f_all = str2double(rain_f_all);
    ff1 = find(rain_f_all < 0);
    rain_f_all(ff1) = NaN;
    
    ps_f_all = str2double(ps_f_all);
    ff2 = find(ps_f_all < 0);
    ps_f_all(ff2) = NaN;
    
    tp_f_all = str2double(tp_f_all);
    ff3 = find(tp_f_all < 0);
    tp_f_all(ff3) = NaN;
    
    rh_f_all = str2double(rh_f_all);
    ff4 = find(rh_f_all < 0);
    rh_f_all(ff4) = NaN;
    
    % 計算一天的總雨量
    rain_1day_sum = NaN(nn,31);
    for ss = 1:nn
        rain_1day = reshape(rain_f_all(:,ss),[24,31]);                                  % 矩陣形狀重組成(24,31)
        rain_1day_sum(ss,:) = sum(rain_1day,1);                                         % 計算一天的總雨量
    end
    
    % 輸出.mat檔案
    eq_date = [num2str(year) '-' month0 '-' day0];
    eq_time = [hour0 ':' minute0 ':' second0];
    save([diro num2str(year) month0 day0 '_M' num2str(mo) '_D' num2str(depth) '.mat'], ...
        'rain_1day_sum','rain_f_all','eq_time','eq_date', ...
        'ps_f_all','tp_f_all','rh_f_all', 'yyyymmdd',...
        'station_dist_all','station_alt_all','station_lat_all','station_lon_all','station_stno_all')
    %break
end