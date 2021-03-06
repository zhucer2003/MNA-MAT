%%Delete the results of previous simulation, if any
if(exist('Results.txt'))
    delete('Results.txt');
elseif(exist('Results.xls'))
    delete('Results.xls');
    if(exist('MC_values_ode.txt'))
        delete('MC_values_ode.txt');
    end
    delete('Voltages_graph.fig');
    if(exist('Currents_graph.fig'))
        delete('Currents_graph.fig');
    end
end
%%-----------------------------------------------------------------------------
prompt='Enter the file name - ';
fname=input(prompt,'s');
netlist_fileID=fopen(fname);
netlist=textscan(netlist_fileID,'%s %s %s %s %s %s');
fclose(netlist_fileID);
runs=input('Enter the number of runs to be performed : ');
disp('----------------------------------------------------------------------------');
for i_i=1:runs
    disp(['RUN ' num2str(i_i)]);
    fileID1=fopen('Element_indep.txt','wt+'); %Create an empty text file Element_indep.txt for passive elements and independent sources
    fileID2=fopen('VCVS.txt','wt+'); %Create an empty text file VCVS.txt for voltage controlled voltage sources
    fileID3=fopen('VCCS.txt','wt+'); %Create an empty text file VCCS.txt for voltage controlled current sources
    fileID4=fopen('CCVS.txt','wt+'); %Create an empty text file CCVS.txt for current controlled voltage sources
    fileID5=fopen('CCCS.txt','wt+'); %Create an empty text file CCCS.txt for current controlled current sources
    %%-----------------------------------------------------------------------------
    %%Initialize
    num_Elements=0; %Number of passive elements
    num_V=0; %Number of independent voltage sources
    num_I=0; %Number of independent current sources
    num_Nodes=0; %Number of nodes, excluding ground (node 0)
    num_VCVS=0; %Number of voltage controlled voltage sources
    num_VCCS=0; %Number of voltage controlled current sources
    num_CCVS=0; %Number of current controlled voltage sources
    num_CCCS=0; %Number of current controlled current sources
    num_R=0; %Number of resistors
    num_L=0; %Number of inductors
    num_C=0; %Number of capacitors
    %%-----------------------------------------------------------------------------
    for i=1:length(netlist{1})
        s=netlist{1}{i};
        switch(s(1))
            case{'R','L','C','V','I'} %For passive elements and independent sources
                fprintf(fileID1,[netlist{1}{i} ' ' netlist{2}{i} ' ' ...
                    netlist{3}{i} ' ' netlist{4}{i} '\n']);
            case{'E'} %For voltage controlled voltage sources
                fprintf(fileID2,[netlist{1}{i} ' ' netlist{2}{i} ' ' ...
                    netlist{3}{i} ' ' netlist{4}{i} ' ' netlist{5}{i} ' ' ...
                    netlist{6}{i} '\n']);
            case{'G'} %For voltage controlled current sources
                fprintf(fileID3,[netlist{1}{i} ' ' netlist{2}{i} ' ' ...
                    netlist{3}{i} ' ' netlist{4}{i} ' ' netlist{5}{i} ' ' ...
                    netlist{6}{i} '\n']);
            case{'H'} %For current controlled voltage sources
                fprintf(fileID4,[netlist{1}{i} ' ' netlist{2}{i} ' ' ...
                    netlist{3}{i} ' ' netlist{4}{i} ' ' netlist{5}{i} '\n']);
            case{'F'} %For current controlled current sources
                fprintf(fileID5,[netlist{1}{i} ' ' netlist{2}{i} ' ' ...
                    netlist{3}{i} ' ' netlist{4}{i} ' ' netlist{5}{i} '\n']);
        end
    end
    %%-----------------------------------------------------------------------------
    %%Read the data from Element_indep.txt text file
    [Name,N1,N2,value]=textread('Element_indep.txt','%s %s %s %s');
    for i=1:length(Name)
        switch(Name{i}(1))
            case{'R'}
                num_Elements=num_Elements+1;
                Element(num_Elements).Name=Name{i};
                Element(num_Elements).Node1=str2num(N1{i});
                Element(num_Elements).Node2=str2num(N2{i});
                Element(num_Elements).Value=str2double(value{i});
                num_R=num_R+1;
                if((i_i==1)&&(num_R==1)) %If first run, and first resistor parsed - obtain resistor distribution information from user
                    dist_R=input('Enter the distribution to be used for resistors :-\n 1. Gaussian (Normal)\n 2. Uniform (Rectangular)\nEnter any other number to keep resistor values fixed at each run\n');
                    if dist_R==1 %Normal distribution
                        SD_R=input('Enter the standard deviation (in %) for resistor Gaussian distribution : ');
                    elseif dist_R==2 %Uniform distribution
                        w_R=input('Enter the window size (in %) for resistor Uniform distribution : ');
                    end
                end
                if dist_R==1   %Gaussian distribution
                    if(SD_R>=0)
                        SD_element = SD_R * Element(num_Elements).Value / 100;
                        %Create a normal distribution object pd_Element with mean = specified element value, and sigma = specified standard deviation
                        pd_Element=makedist('Normal','mu',Element(num_Elements).Value,...
                            'sigma',SD_element);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                    end
                elseif dist_R==2   %Uniform distribution
                    if(w_R>0)
                        a = Element(num_Elements).Value - (Element(num_Elements).Value)*w_R/100;
                        b = Element(num_Elements).Value + (Element(num_Elements).Value)*w_R/100;
                        %Create a uniform distribution object pd_Element with lower value = a, and upper value = b
                        pd_Element=makedist('Uniform','lower',a,'upper',b);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                    end
                end
            case{'C'}
                num_Elements=num_Elements+1;
                Element(num_Elements).Name=Name{i};
                Element(num_Elements).Node1=str2num(N1{i});
                Element(num_Elements).Node2=str2num(N2{i});
                Element(num_Elements).Value=str2double(value{i});
                num_C=num_C+1;
                if((i_i==1)&&(num_C==1)) %If first run, and first capacitor parsed - obtain capacitor distribution information from user
                    dist_C=input('Enter the distribution to be used for capacitors :-\n 1. Gaussian (Normal)\n 2. Uniform (Rectangular)\nEnter any other number to keep capacitor values fixed at each run\n');
                    if dist_C==1 %Normal distribution
                        SD_C=input('Enter the standard deviation (in %) for capacitor Gaussian distribution : ');
                    elseif dist_C==2 %Uniform distribution
                        w_C=input('Enter the window size (in %) for capacitor Uniform distribution : ');
                    end
                end
                if dist_C==1   %Gaussian distribution
                    if(SD_C>=0)
                        SD_element = SD_C * Element(num_Elements).Value / 100;
                        %Create a normal distribution object pd_Element with mean = specified element value, and sigma = specified standard deviation
                        pd_Element=makedist('Normal','mu',Element(num_Elements).Value,...
                            'sigma',SD_element);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                    end
                elseif dist_C==2   %Uniform distribution
                    if(w_C>0)
                        a = Element(num_Elements).Value - (Element(num_Elements).Value)*w_C/100;
                        b = Element(num_Elements).Value + (Element(num_Elements).Value)*w_C/100;
                        %Create a uniform distribution object pd_Element with lower value = a, and upper value = b
                        pd_Element=makedist('Uniform','lower',a,'upper',b);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                    end
                end
            case{'L'}
                num_Elements=num_Elements+1;
                Element(num_Elements).Name=Name{i};
                Element(num_Elements).Node1=str2num(N1{i});
                Element(num_Elements).Node2=str2num(N2{i});
                Element(num_Elements).Value=str2double(value{i});
                num_L=num_L+1;
                Inductor(num_L).Name=Name{i};
                Inductor(num_L).N1=str2num(N1{i});
                Inductor(num_L).N2=str2num(N2{i});
                Inductor(num_L).Value=str2double(value{i});
                if((i_i==1)&&(num_L==1)) %If first run, and first inductor parsed - obtain inductor distribution information from user
                    dist_L=input('Enter the distribution to be used for inductors :-\n 1. Gaussian (Normal)\n 2. Uniform (Rectangular)\nEnter any other number to keep inductor values fixed at each run\n');
                    if dist_L==1 %Normal distribution
                        SD_L=input('Enter the standard deviation (in %) for inductor Gaussian distribution : ');
                    elseif dist_L==2 %Uniform distribution
                        w_L=input('Enter the window size (in %) for inductor Uniform distribution : ');
                    end
                end
                if dist_L==1   %Gaussian distribution
                    if(SD_L>=0)
                        SD_element = SD_L * Element(num_Elements).Value / 100;
                        %Create a normal distribution object pd_Element with mean = specified element value, and sigma = specified standard deviation
                        pd_Element=makedist('Normal','mu',Element(num_Elements).Value,...
                            'sigma',SD_element);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                        Inductor(num_L).Value=r_Element;
                    end
                elseif dist_L==2   %Uniform distribution
                    if(w_L>0)
                        a = Element(num_Elements).Value - (Element(num_Elements).Value)*w_L/100;
                        b = Element(num_Elements).Value + (Element(num_Elements).Value)*w_L/100;
                        %Create a uniform distribution object pd_Element with lower value = a, and upper value = b
                        pd_Element=makedist('Uniform','lower',a,'upper',b);
                        r_Element=random(pd_Element);
                        Element(num_Elements).Value=r_Element;
                        Inductor(num_L).Value=r_Element;
                    end
                end
            case{'V'}
                num_V=num_V+1;
                Volt_source(num_V).Name=Name{i};
                Volt_source(num_V).Node1=str2num(N1{i});
                Volt_source(num_V).Node2=str2num(N2{i});
                Volt_source(num_V).Value=str2double(value{i});
                
            case{'I'}
                num_I=num_I+1;
                Current_source(num_I).Name=Name{i};
                Current_source(num_I).Node1=str2num(N1{i});
                Current_source(num_I).Node2=str2num(N2{i});
                Current_source(num_I).Value=str2double(value{i});
        end
        num_Nodes=max(str2num(N1{i}),max(str2num(N2{i}),num_Nodes));
    end
    %%-----------------------------------------------------------------------------
    %%Read the data from VCVS.txt text file
    [Name,N1,N2,NC1,NC2,Gain]=textread('VCVS.txt','%s %s %s %s %s %s');
    num_VCVS=length(Name);
    for i=1:num_VCVS
        VCVS(i).Name=Name{i};
        VCVS(i).N1=str2num(N1{i});
        VCVS(i).N2=str2num(N2{i});
        VCVS(i).NC1=str2num(NC1{i});
        VCVS(i).NC2=str2num(NC2{i});
        VCVS(i).Gain=str2double(Gain{i});
        num_Nodes=max(str2num(N1{i}),max(str2num(N2{i}),num_Nodes));
    end
    %%-----------------------------------------------------------------------------
    %%Read the data from VCCS.txt text file
    [Name,N1,N2,NC1,NC2,Transconductance]=textread('VCCS.txt','%s %s %s %s %s %s');
    num_VCCS=length(Name);
    for i=1:num_VCCS
        VCCS(i).Name=Name{i};
        VCCS(i).N1=str2num(N1{i});
        VCCS(i).N2=str2num(N2{i});
        VCCS(i).NC1=str2num(NC1{i});
        VCCS(i).NC2=str2num(NC2{i});
        VCCS(i).Transconductance=str2double(Transconductance{i});
        num_Nodes=max(str2num(N1{i}),max(str2num(N2{i}),num_Nodes));
    end
    %%-----------------------------------------------------------------------------
    %%Read the data from CCVS.txt text file
    [Name,N1,N2,Vcontrol,Transresistance]=textread('CCVS.txt','%s %s %s %s %s');
    num_CCVS=length(Name);
    for i=1:num_CCVS
        CCVS(i).Name=Name{i};
        CCVS(i).N1=str2num(N1{i});
        CCVS(i).N2=str2num(N2{i});
        CCVS(i).Vcontrol=Vcontrol{i};
        CCVS(i).Transresistance=str2double(Transresistance{i});
        num_Nodes=max(str2num(N1{i}),max(str2num(N2{i}),num_Nodes));
    end
    %%-----------------------------------------------------------------------------
    %%Read the data from CCCS.txt text file
    [Name,N1,N2,Vcontrol,Gain]=textread('CCCS.txt','%s %s %s %s %s');
    num_CCCS=length(Name);
    for i=1:num_CCCS
        CCCS(i).Name=Name{i};
        CCCS(i).N1=str2num(N1{i});
        CCCS(i).N2=str2num(N2{i});
        CCCS(i).Vcontrol=Vcontrol{i};
        CCCS(i).Gain=str2double(Gain{i});
        num_Nodes=max(str2num(N1{i}),max(str2num(N2{i}),num_Nodes));
    end
    %%-----------------------------------------------------------------------------
    %%Close the no longer required text files and then delete them
    fclose(fileID1);
    fclose(fileID2);
    fclose(fileID3);
    fclose(fileID4);
    fclose(fileID5);
    delete('Element_indep.txt');
    delete('VCVS.txt');
    delete('VCCS.txt');
    delete('CCVS.txt');
    delete('CCCS.txt');
    %%-----------------------------------------------------------------------------
    %%Create the equations for the independent voltage sources and apply KCL at the nodes
    node_equation=cell(num_Nodes,1);
    volt_equation=cell(num_V,1);
    for i=1:num_V
        switch((Volt_source(i).Node1==0)||(Volt_source(i).Node2==0))
            case{1}
                if(Volt_source(i).Node1==0)
                    volt=['v_' num2str(Volt_source(i).Node2) '=' '-' num2str(Volt_source(i).Value)];
                    node_equation{Volt_source(i).Node2}=[node_equation{Volt_source(i).Node2} ...
                        '-' 'i_' Volt_source(i).Name];
                else
                    volt=['v_' num2str(Volt_source(i).Node1) '='  num2str(Volt_source(i).Value)];
                    node_equation{Volt_source(i).Node1}=[node_equation{Volt_source(i).Node1} ...
                        '+' 'i_' Volt_source(i).Name];
                end
                volt_equation{i}=volt;
            case{0}
                volt=['v_' num2str(Volt_source(i).Node1) '-' ...
                    'v_' num2str(Volt_source(i).Node2) '=' num2str(Volt_source(i).Value)];
                volt_equation{i}=volt;
                node_equation{Volt_source(i).Node1}=[node_equation{Volt_source(i).Node1} ...
                    '+' 'i_' Volt_source(i).Name];
                node_equation{Volt_source(i).Node2}=[node_equation{Volt_source(i).Node2} ...
                    '-' 'i_' Volt_source(i).Name];
        end
    end
    %%-----------------------------------------------------------------------------
    %%Create the equations for the voltage controlled voltage sources and apply KCL at the nodes
    VCVS_equation=cell(num_VCVS,1);
    for i=1:num_VCVS
        switch((VCVS(i).N1==0)||(VCVS(i).N2==0))
            case{1}
                if(VCVS(i).N1==0)
                    switch((VCVS(i).NC1==0)||(VCVS(i).NC2==0))
                        case{1}
                            if(VCVS(i).NC1==0)
                                volt=['-' 'v_' num2str(VCVS(i).N2) '-' num2str(VCVS(i).Gain) ...
                                    '*' '(' '-' 'v_' num2str(VCVS(i).NC2) ')'];
                            else
                                volt=['-' 'v_' num2str(VCVS(i).N2) '-' num2str(VCVS(i).Gain) ...
                                    '*' '(' 'v_' num2str(VCVS(i).NC1) ')'];
                            end
                        case{0}
                            volt=['-' 'v_' num2str(VCVS(i).N2) '-' num2str(VCVS(i).Gain) ...
                                '*' '(' 'v_' num2str(VCVS(i).NC1) '-' 'v_' num2str(VCVS(i).NC2) ')'];
                    end
                    node_equation{VCVS(i).N2}=[node_equation{VCVS(i).N2} '-' 'i_' VCVS(i).Name];
                else
                    switch((VCVS(i).NC1==0)||(VCVS(i).NC2==0))
                        case{1}
                            if(VCVS(i).NC1==0)
                                volt=['v_' num2str(VCVS(i).N1) '-' num2str(VCVS(i).Gain) ...
                                    '*' '(' '-' 'v_' num2str(VCVS(i).NC2) ')'];
                            else
                                volt=['v_' num2str(VCVS(i).N1) '-' num2str(VCVS(i).Gain) ...
                                    '*' '(' 'v_' num2str(VCVS(i).NC1) ')'];
                            end
                        case{0}
                            volt=['v_' num2str(VCVS(i).N1) '-' num2str(VCVS(i).Gain) ...
                                '*' '(' 'v_' num2str(VCVS(i).NC1) '-' 'v_' num2str(VCVS(i).NC2) ')'];
                    end
                    node_equation{VCVS(i).N1}=[node_equation{VCVS(i).N1} '+' 'i_' VCVS(i).Name];
                end
            case{0}
                switch((VCVS(i).NC1==0)||(VCVS(i).NC2==0))
                    case{1}
                        if(VCVS(i).NC1==0)
                            volt=['v_' num2str(VCVS(i).N1) '-' 'v_' num2str(VCVS(i).N2) '-' ...
                                num2str(VCVS(i).Gain) '*' '(' '-' 'v_' num2str(VCVS(i).NC2) ')'];
                        else
                            volt=['v_' num2str(VCVS(i).N1) '-' 'v_' num2str(VCVS(i).N2) '-' ...
                                num2str(VCVS(i).Gain) '*' '(' 'v_' num2str(VCVS(i).NC1) ')'];
                        end
                    case{0}
                        volt=['v_' num2str(VCVS(i).N1) '-' 'v_' num2str(VCVS(i).N2) '-' ...
                            num2str(VCVS(i).Gain) '*' '(' 'v_' num2str(VCVS(i).NC1) '-' 'v_' num2str(VCVS(i).NC2) ')'];
                end
                node_equation{VCVS(i).N1}=[node_equation{VCVS(i).N1} '+' 'i_' VCVS(i).Name];
                node_equation{VCVS(i).N2}=[node_equation{VCVS(i).N2} '-' 'i_' VCVS(i).Name];
        end
        VCVS_equation{i}=volt;
    end
    %%-----------------------------------------------------------------------------
    %%Create the equations for the current controlled voltage sources and apply KCL at the nodes
    CCVS_equation=cell(num_CCVS,1);
    for i=1:num_CCVS
        switch((CCVS(i).N1==0)||(CCVS(i).N2==0))
            case{1}
                if(CCVS(i).N1==0)
                    volt=['v_' num2str(CCVS(i).N2) '+' '(' num2str(CCVS(i).Transresistance) '*' 'i_' CCVS(i).Vcontrol ')'];
                    node_equation{CCVS(i).N2}=[node_equation{CCVS(i).N2} ...
                        '-' 'i_' CCVS(i).Name];
                else
                    volt=['v_' num2str(CCVS(i).N1) '-' '(' num2str(CCVS(i).Transresistance) '*' 'i_' CCVS(i).Vcontrol ')'];
                    node_equation{CCVS(i).N1}=[node_equation{CCVS(i).N1} ...
                        '+' 'i_' CCVS(i).Name];
                end
                CCVS_equation{i}=volt;
            case{0}
                volt=['v_' num2str(CCVS(i).N1) '-' ...
                    'v_' num2str(CCVS(i).N2) '-' '(' num2str(CCVS(i).Transresistance) '*' 'i_' CCVS(i).Vcontrol ')'];
                CCVS_equation{i}=volt;
                node_equation{CCVS(i).N1}=[node_equation{CCVS(i).N1} ...
                    '+' 'i_' CCVS(i).Name];
                node_equation{CCVS(i).N2}=[node_equation{CCVS(i).N2} ...
                    '-' 'i_' CCVS(i).Name];
        end
    end
    %%-----------------------------------------------------------------------------
    solver_flag=0; %A flag used for deciding which solver to finally use
    %solver_flag=0 => Purely resistive circuit, use solve for the equations
    %solver_flag=1 => Pure C, pure L, LC, RC, RL or RLC circuit, use ode15i for the equations
    %%-----------------------------------------------------------------------------
    %%Add the passive element currents using KCL to the node equations, and make the equations for inductors
    L_equation=cell(num_L,1);
    L_ctr=0;
    for i=1:num_Elements
        switch(Element(i).Name(1))
            case{'R'}
                switch((Element(i).Node1==0)||(Element(i).Node2==0))
                    case{0}
                        node_equation{Element(i).Node1}=[node_equation{Element(i).Node1} '+' '(' ...
                            'v_' num2str(Element(i).Node2) '-' 'v_' ...
                            num2str(Element(i).Node1) ')' '/' num2str(Element(i).Value)];
                        node_equation{Element(i).Node2}=[node_equation{Element(i).Node2} '+' '(' ...
                            'v_' num2str(Element(i).Node1) '-' 'v_' ...
                            num2str(Element(i).Node2) ')' '/' num2str(Element(i).Value)];
                    case{1}
                        if(Element(i).Node1==0)
                            node_equation{Element(i).Node2}=[node_equation{Element(i).Node2} ...
                                '-' '(' 'v_' num2str(Element(i).Node2) ')' '/' num2str(Element(i).Value)];
                        else
                            node_equation{Element(i).Node1}=[node_equation{Element(i).Node1} ...
                                '-' '(' 'v_' num2str(Element(i).Node1) ')' '/' num2str(Element(i).Value)];
                        end
                end
            case{'C'}
                if(solver_flag==0)
                    solver_flag=1;
                end
                switch((Element(i).Node1==0)||(Element(i).Node2==0))
                    case{0}
                        node_equation{Element(i).Node1}=[node_equation{Element(i).Node1} ...
                            '+' num2str(Element(i).Value) '*' '(' 'vp(' num2str(Element(i).Node2) ')' ...
                            '-' 'vp(' num2str(Element(i).Node1) ')' ')'];
                        node_equation{Element(i).Node2}=[node_equation{Element(i).Node2} ...
                            '+' num2str(Element(i).Value) '*' '(' 'vp(' num2str(Element(i).Node1) ')' ...
                            '-' 'vp(' num2str(Element(i).Node2) ')' ')'];
                    case{1}
                        if(Element(i).Node1==0)
                            node_equation{Element(i).Node2}=[node_equation{Element(i).Node2} ...
                                '-' num2str(Element(i).Value) '*' '(' 'vp(' num2str(Element(i).Node2) ')' ')'];
                        else
                            node_equation{Element(i).Node1}=[node_equation{Element(i).Node1} ...
                                '-' num2str(Element(i).Value) '*' '(' 'vp(' num2str(Element(i).Node1) ')' ')'];
                        end
                end
            case{'L'}
                if(solver_flag==0)
                    solver_flag=1;
                end
                L_ctr=L_ctr+1;
                switch((Element(i).Node1==0)||(Element(i).Node2==0))
                    case{0}
                        node_equation{Element(i).Node1}=[node_equation{Element(i).Node1} '-' 'i_' Element(i).Name];
                        node_equation{Element(i).Node2}=[node_equation{Element(i).Node2} '+' 'i_' Element(i).Name];
                        L_equation{L_ctr}=['v_' num2str(Element(i).Node1) '-' 'v_' num2str(Element(i).Node2) '-' ...
                            '('  num2str(Element(i).Value) '*' 'ip(' num2str(L_ctr) ')' ')'];
                    case{1}
                        if(Element(i).Node1==0)
                            node_equation{Element(i).Node2}=[node_equation{Element(i).Node2}  '+' 'i_' Element(i).Name];
                            L_equation{L_ctr}=['-' 'v_' num2str(Element(i).Node2) '-' ...
                                '('  num2str(Element(i).Value) '*' 'ip(' num2str(L_ctr) ')' ')'];
                        else
                            node_equation{Element(i).Node1}=[node_equation{Element(i).Node1}  '-' 'i_' Element(i).Name];
                            L_equation{L_ctr}=['v_' num2str(Element(i).Node1) '-' ...
                                '('  num2str(Element(i).Value) '*' 'ip(' num2str(L_ctr) ')' ')'];
                        end
                end
        end
    end
    %%-----------------------------------------------------------------------------
    %%Add the independent current sources using KCL to the node equations
    for i=1:num_I
        switch((Current_source(i).Node1==0)||(Current_source(i).Node2==0))
            case{1}
                if(Current_source(i).Node1==0)
                    node_equation{Current_source(i).Node2}=[node_equation{Current_source(i).Node2} ...
                        '+' num2str(Current_source(i).Value)];
                else
                    node_equation{Current_source(i).Node1}=[node_equation{Current_source(i).Node1} ...
                        '-' num2str(Current_source(i).Value)];
                end
            case{0}
                node_equation{Current_source(i).Node1}=[node_equation{Current_source(i).Node1} ...
                    '-' num2str(Current_source(i).Value)];
                node_equation{Current_source(i).Node2}=[node_equation{Current_source(i).Node2} ...
                    '+' num2str(Current_source(i).Value)];
        end
    end
    %%-----------------------------------------------------------------------------
    %%Next, add the voltage controlled current sources using KCL to the node equations
    for i=1:num_VCCS
        switch((VCCS(i).N1==0)||(VCCS(i).N2==0))
            case{1}
                if(VCCS(i).N1==0)
                    switch((VCCS(i).NC1==0)||(VCCS(i).NC2==0))
                        case{1}
                            if(VCCS(i).NC1==0)
                                node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                                    num2str(VCCS(i).Transconductance) '*' '(' '-' 'v_' num2str(VCCS(i).NC2) ')'];
                            else
                                node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                                    num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) ')'];
                            end
                        case{0}
                            node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                                num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) '-' ...
                                'v_' num2str(VCCS(i).NC2) ')'];
                    end
                else
                    switch((VCCS(i).NC1==0)||(VCCS(i).NC2==0))
                        case{1}
                            if(VCCS(i).NC1==0)
                                node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                                    num2str(VCCS(i).Transconductance) '*' '(' '-' 'v_' num2str(VCCS(i).NC2) ')'];
                            else
                                node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                                    num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) ')'];
                            end
                        case{0}
                            node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                                num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) ...
                                '-' 'v_' num2str(VCCS(i).NC2) ')'];
                    end
                end
            case{0}
                switch((VCCS(i).NC1==0)||(VCCS(i).NC2==0))
                    case{1}
                        if(VCCS(i).NC1==0)
                            node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                                num2str(VCCS(i).Transconductance) '*' '(' '-' 'v_' num2str(VCCS(i).NC2) ')'];
                            node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                                num2str(VCCS(i).Transconductance) '*' '(' '-' 'v_' num2str(VCCS(i).NC2) ')'];
                        else
                            node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                                num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) ')'];
                            node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                                num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) ')'];
                        end
                    case{0}
                        node_equation{VCCS(i).N1}=[node_equation{VCCS(i).N1} '-' ...
                            num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) '-' ...
                            'v_' num2str(VCCS(i).NC2) ')'];
                        node_equation{VCCS(i).N2}=[node_equation{VCCS(i).N2} '+' ...
                            num2str(VCCS(i).Transconductance) '*' '(' 'v_' num2str(VCCS(i).NC1) '-' ...
                            'v_' num2str(VCCS(i).NC2) ')'];
                end
        end
    end
    %%-----------------------------------------------------------------------------
    %%Finally, add the current controlled current sources using KCL to the node equations
    for i=1:num_CCCS
        switch((CCCS(i).N1==0)||(CCCS(i).N2==0))
            case{1}
                if(CCCS(i).N1==0)
                    node_equation{CCCS(i).N2}=[node_equation{CCCS(i).N2} ...
                        '+' '(' num2str(CCCS(i).Gain) '*' 'i_' CCCS(i).Vcontrol ')'];
                else
                    node_equation{CCCS(i).N1}=[node_equation{CCCS(i).N1} ...
                        '-' '(' num2str(CCCS(i).Gain) '*' 'i_' CCCS(i).Vcontrol ')'];
                end
            case{0}
                node_equation{CCCS(i).N1}=[node_equation{CCCS(i).N1} ...
                    '-' '(' num2str(CCCS(i).Gain) '*' 'i_' CCCS(i).Vcontrol ')'];
                node_equation{CCCS(i).N2}=[node_equation{CCCS(i).N2} ...
                    '+' '(' num2str(CCCS(i).Gain) '*' 'i_' CCCS(i).Vcontrol ')'];
        end
    end
    %%-----------------------------------------------------------------------------
    %%If solver_flag=0 (purely resistive circuit), add the RHS('=0') to each
    %%nodal KCL equation, to each VCVS equation, and to each CCVS equation
    if(solver_flag==0)
        for i=1:length(node_equation)
            node_equation{i}=[node_equation{i} '=' '0'];
        end
        for i=1:length(VCVS_equation)
            VCVS_equation{i}=[VCVS_equation{i} '=' '0'];
        end
        for i=1:length(CCVS_equation)
            CCVS_equation{i}=[CCVS_equation{i} '=' '0'];
        end
        %%Else if solver_flag=1 (Pure C, pure L, LC, RC, RL or RLC circuit), do NOT add the RHS ('=0')
        %%to each nodal KCL equation, to each VCVS equation, to each CCVS equation and to each inductor equation, instead replace
        %%the node voltage terms v_1,v_2,...v_num_Nodes in LHS of all the equations with v(1),v(2),...v(num_Nodes) respectively,
        %%modify each independent voltage source equation to only LHS [no RHS ('=0')] (similar to all the other equations),
        %%also replace the independent voltage source current terms with v(num_Nodes+j) (j=1:num_V)
        %%VCVS current terms with v(num_Nodes+num_V+j) (j=1:num_VCVS)
        %%CCVS current terms with v(num_Nodes+num_V+num_VCVS+j) (j=1:num_CCVS)
        %%and inductor current terms with v(num_Nodes+num_V+num_VCVS+num_CCVS+j) (j=1:num_L)
    elseif(solver_flag==1)
        for i=1:num_Nodes %For each nodal KCL equation (only LHS)
            for j=1:num_Nodes
                node_equation{i}=strrep(node_equation{i},['v_' num2str(j)],['v(' num2str(j) ')']);
            end
            for j=1:num_V
                node_equation{i}=strrep(node_equation{i},['i_' Volt_source(j).Name],['v(' num2str(num_Nodes+j) ')']);
            end
            for j=1:num_VCVS
                node_equation{i}=strrep(node_equation{i},['i_' VCVS(j).Name],['v(' num2str(num_Nodes+num_V+j) ')']);
            end
            for j=1:num_CCVS
                node_equation{i}=strrep(node_equation{i},['i_' CCVS(j).Name],['v(' num2str(num_Nodes+num_V+num_VCVS+j) ')']);
            end
            for j=1:num_L
                node_equation{i}=strrep(node_equation{i},['i_' Inductor(j).Name],['v(' num2str(num_Nodes+num_V+num_VCVS+num_CCVS+j) ')']);
            end
        end
        for i=1:num_V %For each independent voltage source equation
            for j=1:num_Nodes
                volt_equation{i}=strrep(volt_equation{i},['v_' num2str(j)],['v(' num2str(j) ')']);
            end
            volt_equation{i}=strrep(volt_equation{i},'=','-'); %Modify each independent voltage source equation to only LHS [no RHS ('=0')]
        end
        for i=1:num_VCVS %For each VCVS equation (only LHS)
            for j=1:num_Nodes
                VCVS_equation{i}=strrep(VCVS_equation{i},['v_' num2str(j)],['v(' num2str(j) ')']);
            end
        end
        for i=1:num_CCVS %For each CCVS equation (only LHS)
            for j=1:num_Nodes
                CCVS_equation{i}=strrep(CCVS_equation{i},['v_' num2str(j)],['v(' num2str(j) ')']);
            end
            for j=1:num_V
                CCVS_equation{i}=strrep(CCVS_equation{i},['i_' Volt_source(j).Name],['v(' num2str(num_Nodes+j) ')']);
            end
            for j=1:num_VCVS
                CCVS_equation{i}=strrep(CCVS_equation{i},['i_' VCVS(j).Name],['v(' num2str(num_Nodes+num_V+j) ')']);
            end
            for j=1:num_CCVS
                CCVS_equation{i}=strrep(CCVS_equation{i},['i_' CCVS(j).Name],['v(' num2str(num_Nodes+num_V+num_VCVS+j) ')']);
            end
        end
        for i=1:num_L %For each inductor equation (only LHS)
            for j=1:num_Nodes
                L_equation{i}=strrep(L_equation{i},['v_' num2str(j)],['v(' num2str(j) ')']);
            end
        end
    end
    %%-----------------------------------------------------------------------------
    eqn=cell(num_Nodes+num_V+num_VCVS+num_CCVS+num_L,1);
    for i=1:num_Nodes
        eqn{i}=evalin(symengine,node_equation{i});
    end
    for i=1:num_V
        eqn{num_Nodes+i}=evalin(symengine,volt_equation{i});
    end
    for i=1:num_VCVS
        eqn{num_Nodes+num_V+i}=evalin(symengine,VCVS_equation{i});
    end
    for i=1:num_CCVS
        eqn{num_Nodes+num_V+num_VCVS+i}=evalin(symengine,CCVS_equation{i});
    end
    for i=1:num_L
        eqn{num_Nodes+num_V+num_VCVS+num_CCVS+i}=evalin(symengine,L_equation{i});
    end
    %%-----------------------------------------------------------------------------
    switch(solver_flag)
        case{0}
            if(i_i==1) %If first run
                %Create the symbolic variables for node voltages and currents through voltage sources
                variables='syms';
                for i=1:num_Nodes
                    variables=[variables ' ' 'v_' num2str(i)];
                end
                for i=1:num_V
                    variables=[variables ' ' 'i_' Volt_source(i).Name];
                end
                for i=1:num_VCVS
                    variables=[variables ' ' 'i_' VCVS(i).Name];
                end
                for i=1:num_CCVS
                    variables=[variables ' ' 'i_' CCVS(i).Name];
                end
                eval(variables);
                %----------------------------------------------
                %Create a row vector var of the symbolic variables created above - to be used in solve at each run
                var_string=['var=[' variables(6:end) ']'];
                eval(var_string);
                %----------------------------------------------
                %Create the symbolic variables for the symbolic equations
                equations='syms';
                for i=1:(num_Nodes+num_V+num_VCVS+num_CCVS)
                    equations=[equations ' ' 'eqn' num2str(i)];
                end
                eval(equations);
                %----------------------------------------------
                %Create a row vector eqn_solve of the equation symbolic variables
                interm_string=['eqn_solve=[' equations(6:end) ']'];
                eval(interm_string);
            end
            %----------------------------------------------
            %Assign the equation symbolic variables with the corresponding symbolic equations
            for i=1:(num_Nodes+num_V+num_VCVS+num_CCVS)
                eqn_string=['eqn' num2str(i) '=' 'eqn{' num2str(i) '}'];
                eval(eqn_string);
            end
            %----------------------------------------------
            %Solve the symbolic linear equations using solve
            sol=solve(eval(eqn_solve),var);
            %Note :- We use eval(eqn_solve) to substitute the symbolic equation associated with
            %each equation symbolic variable
            %----------------------------------------------
            if(i_i==1) %If first run
                F=fopen('Results.txt','wt+'); %Create an empty text file Results.txt
                date=datetime('now');
                date_string=datestr(date);
                fprintf(F,date_string);
                fprintf(F,'\n');
                fprintf(F,['File name : ' fname]);
                fprintf(F,'\n');
                if(dist_R==1)
                    fprintf(F,'Resistor Distribution : Normal');
                    fprintf(F,'\n');
                    fprintf(F,['Resistor Standard deviation in %% : ' num2str(SD_R)]);
                    fprintf(F,'\n');
                elseif(dist_R==2)
                    fprintf(F,'Resistor Distribution : Uniform');
                    fprintf(F,'\n');
                    fprintf(F,['Resistor Window size in %% : ' num2str(w_R)]);
                    fprintf(F,'\n');
                else
                    fprintf(F,'Resistor Distribution : None');
                    fprintf(F,'\n');
                end
                fprintf(F,['Number of runs : ' num2str(runs)]);
                fprintf(F,'\n');
                fprintf(F,'---------------------------------------------------------------------------- \n');
            end
            fprintf(F,['RUN ' num2str(i_i)]);
            fprintf(F,'\n \n');
            it = 1;
            for j=1:num_Elements
                fprintf(F,Element(j).Name);
                fprintf(F,' = ');
                fprintf(F,[num2str(Element(j).Value) '\n']);
            end
            fprintf(F,'---------------------------------------------------------------------------- \n');
            fprintf(F,'NODE VOLTAGES \n');
            for i=1:num_Nodes
                fprintf(F,['v_' num2str(i) ' = ']);
                fprintf(F,num2str(eval(eval(['sol.v_' num2str(i)]))));
                fprintf(F,'\n');
                table(i_i, it) = eval(eval(['sol.v_' num2str(i)]));
                it = it + 1;
            end
            fprintf(F,'---------------------------------------------------------------------------- \n');
            if(num_V~=0)
                fprintf(F,'CURRENTS THROUGH INDEPENDENT VOLTAGE SOURCES (NEGATIVE TO POSITIVE TERMINAL) \n');
                for i=1:num_V
                    fprintf(F,['i_' Volt_source(i).Name ' = ']);
                    fprintf(F,num2str(eval(eval(['sol.i_' Volt_source(i).Name]))));
                    fprintf(F,'\n');
                    table(i_i, it) = eval(eval(['sol.i_' Volt_source(i).Name]));
                    it = it + 1;
                end
                fprintf(F,'---------------------------------------------------------------------------- \n');
            end
            if(num_VCVS~=0)
                fprintf(F,'CURRENTS THROUGH VOLTAGE CONTROLLED VOLTAGE SOURCES (NEGATIVE TO POSITIVE TERMINAL) \n');
                for i=1:num_VCVS
                    fprintf(F,['i_' VCVS(i).Name ' = ']);
                    fprintf(F,num2str(eval(eval(['sol.i_' VCVS(i).Name]))));
                    fprintf(F,'\n');
                    table(i_i, it) = eval(eval(['sol.i_' VCVS(i).Name]));
                    it = it + 1;
                end
                fprintf(F,'---------------------------------------------------------------------------- \n');
            end
            if(num_CCVS~=0)
                fprintf(F,'CURRENTS THROUGH CURRENT CONTROLLED VOLTAGE SOURCES (NEGATIVE TO POSITIVE TERMINAL) \n');
                for i=1:num_CCVS
                    fprintf(F,['i_' CCVS(i).Name ' = ']);
                    fprintf(F,num2str(eval(eval(['sol.i_' CCVS(i).Name]))));
                    fprintf(F,'\n');
                    table(i_i, it) = eval(eval(['sol.i_' CCVS(i).Name]));
                    it = it + 1;
                end
                fprintf(F,'---------------------------------------------------------------------------- \n');
            end
            if(i_i==runs) %If last run
                type('Results.txt');  %Display the contents of Results.txt text file
                fclose(F); %Close the Results.txt text file
                [m,n] = size(table);
                x = 1:m;
                for i=1:num_Nodes   %Plot each node voltage recorded at each run
                    figure;
                    quant = table(:,i);
                    stem(x,quant);
                    xlabel('RUN');
                    ylabel(['v\_' num2str(i) ' (V)']);
                end
                for i=1:num_V   %Plot each independent voltage source current recorded at each run
                    figure;
                    quant = table(:,(num_Nodes+i));
                    stem(x,quant);
                    xlabel('RUN');
                    ylabel(['i\_' Volt_source(i).Name ' (A)']);
                end
                for i=1:num_VCVS   %Plot each VCVS current recorded at each run
                    figure;
                    quant = table(:,(num_Nodes+num_V+i));
                    stem(x,quant);
                    xlabel('RUN');
                    ylabel(['i\_' VCVS(i).Name ' (A)']);
                end
                for i=1:num_CCVS   %Plot each CCVS current recorded at each run
                    figure;
                    quant = table(:,(num_Nodes+num_V+num_VCVS+i));
                    stem(x,quant);
                    xlabel('RUN');
                    ylabel(['i\_' CCVS(i).Name ' (A)']);
                end
            end
            %%-----------------------------------------------------------------------------
        case{1}
            %Create the state variables for node voltages, currents through voltage sources and inductor currents
            variables='syms';
            for i=1:(num_Nodes+num_V+num_VCVS+num_CCVS+num_L)
                variables=[variables ' ' 'v' num2str(i) '(t)'];
            end
            eval(variables);
            %----------------------------------------------
            %Create a row vector var of the state variables - to be used in daeFunction
            var_string=['var=[' variables(6:end) ']'];
            eval(var_string);
            %----------------------------------------------
            %Convert the symbolic equations (only LHS) to a form suitable for daeFunction
            %Use the converted symbolic equations to make a row vector eqn_daeFunction - to be used in daeFunction
            eqn_string='eqn_daeFunction=[';
            for i=1:length(eqn)
                interm_string=char(eqn{i});
                for j=1:(num_Nodes+num_V+num_VCVS+num_CCVS+num_L)
                    interm_string=strrep(interm_string,['v(' num2str(j) ')'],['v' num2str(j) '(t)']);
                end
                for j=1:num_Nodes
                    interm_string=strrep(interm_string,['vp(' num2str(j) ')'],['diff(v' num2str(j) ...
                        '(t)' ',t)']);
                end
                for j=1:num_L
                    interm_string=strrep(interm_string,['ip(' num2str(j) ')'],['diff(v' num2str(num_Nodes+num_V+num_VCVS+num_CCVS+j) ...
                        '(t)' ',t)']);
                end
                eqn_string=[eqn_string interm_string ','];
            end
            eqn_string=[eqn_string ']'];
            eval(eqn_string);
            %----------------------------------------------
            %Use daeFunction to create the function handle odefun
            odefun=daeFunction(eqn_daeFunction,var);
            %----------------------------------------------
            %Use ode15i along with created function handle odefun
            v0=zeros(length(eqn_daeFunction),1); %Initial conditions for v
            vp0=zeros(length(eqn_daeFunction),1); %Initial conditions for v'
            if(i_i==1)   %If first run, obtain the simulation time tf for each run from the user
                fprintf('The transient analysis at each run will be performed from t=0 to t=tf');
                fprintf('\n');
                tf=input('Enter the final time value tf in seconds : ');
            end
            options=odeset('RelTol',1e-03,'AbsTol',1e-03);
            [t,v]=ode15i(odefun,[0 tf],v0,vp0,options);
            %----------------------------------------------
            if(i_i==1) %If first run
                G=fopen('MC_values_ode.txt','wt+'); %Create an empty text file MC_values_ode.txt
            end
            fprintf(G,['RUN ' num2str(i_i)]);
            fprintf(G,'\n \n');
            for j=1:num_Elements
                fprintf(G,[Element(j).Name ' = ' num2str(Element(j).Value)]);
                fprintf(G,'\n');
            end
            fprintf(G,'---------------------------------------------------------------------------- \n');
            if(i_i==1)
                table_heading=cell(1,(1+num_Nodes+num_V+num_VCVS));
                table_heading{1}='Time';
                for j=1:num_Nodes
                    table_heading{1+j}=['v_' num2str(j)];
                end
                for j=1:num_V
                    table_heading{1+num_Nodes+j}=['i_' Volt_source(j).Name];
                end
                for j=1:num_VCVS
                    table_heading{1+num_Nodes+num_V+j}=['i_' VCVS(j).Name];
                end
                for j=1:num_CCVS
                    table_heading{1+num_Nodes+num_V+num_VCVS+j}=['i_' CCVS(j).Name];
                end
                for j=1:num_L
                    table_heading{1+num_Nodes+num_V+num_VCVS+num_CCVS+j}=['i_' Inductor(j).Name];
                end
            end
            T=array2table([t,v],'VariableNames',table_heading);
            if(i_i==1) %If first run
                orig_state=warning('query','MATLAB:xlswrite:AddSheet'); %Save the current state of warning 'MATLAB:xlswrite:AddSheet' in structure array orig_state
                warning('off','MATLAB:xlswrite:AddSheet'); %Turn off 'MATLAB:xlswrite:AddSheet' warning
                date=datetime('now');
                date_string=datestr(date);
                xlswrite('Results.xls',{date_string});
                xlswrite('Results.xls',{['File name : ' fname]},1,'A2');
                if(num_R~=0)
                    if(dist_R==1)
                        xlswrite('Results.xls',{'Resistor Distribution : Normal'},1,'A3');
                        xlswrite('Results.xls',{['Resistor SD in % : ' num2str(SD_R)]},1,'A4');
                    elseif(dist_R==2)
                        xlswrite('Results.xls',{'Resistor Distribution : Uniform'},1,'A3');
                        xlswrite('Results.xls',{['Resistor Window size % : ' num2str(w_R)]},1,'A4');
                    else
                        xlswrite('Results.xls',{'Resistor Distribution : None'},1,'A3');
                    end
                end
                if(num_C~=0)
                    if(dist_C==1)
                        xlswrite('Results.xls',{'Capacitor Distribution : Normal'},1,'A5');
                        xlswrite('Results.xls',{['Capacitor SD in % : ' num2str(SD_C)]},1,'A6');
                    elseif(dist_C==2)
                        xlswrite('Results.xls',{'Capacitor Distribution : Uniform'},1,'A5');
                        xlswrite('Results.xls',{['Capacitor Window size % : ' num2str(w_C)]},1,'A6');
                    else
                        xlswrite('Results.xls',{'Capacitor Distribution : None'},1,'A5');
                    end
                end
                if(num_L~=0)
                    if(dist_L==1)
                        xlswrite('Results.xls',{'Inductor Distribution : Normal'},1,'A7');
                        xlswrite('Results.xls',{['Inductor SD in % : ' num2str(SD_L)]},1,'A8');
                    elseif(dist_L==2)
                        xlswrite('Results.xls',{'Inductor Distribution : Uniform'},1,'A7');
                        xlswrite('Results.xls',{['Inductor Window size % : ' num2str(w_L)]},1,'A8');
                    else
                        xlswrite('Results.xls',{'Inductor Distribution : None'},1,'A7');
                    end
                end
                xlswrite('Results.xls',{['Runs : ' num2str(runs)]},1,'A9');
            end
            writetable(T,'Results.xls','Range','A11','Sheet',i_i);
            figure(1);
            plot(t,v(:,1:num_Nodes));hold on; %Plot the node voltages vs. time
            if(i_i==1)
                legend_voltage='legend(';
            end
            for i=1:num_Nodes
                interm_string=table_heading{1+i};
                interm_string=strrep(interm_string,'_','\_');
                legend_voltage=[legend_voltage '''' interm_string ' (RUN ' num2str(i_i) ')'   '''' ','];
            end
            if(i_i==runs)
                legend_voltage(end)=')';
                eval(legend_voltage);
                xlabel('TIME (s)');
                ylabel('NODE VOLTAGES (V)');
            end
            if((num_V~=0)||(num_VCVS~=0)||(num_CCVS~=0)||(num_L~=0))
                figure(2);
                plot(t,v(:,(num_Nodes+1):end));hold on; %Plot the currents through voltage sources and inductor currents vs. time
                if(i_i==1)
                    legend_current='legend(';
                end
                for i=1:num_V
                    interm_string=table_heading{1+num_Nodes+i};
                    interm_string=strrep(interm_string,'_','\_');
                    legend_current=[legend_current '''' interm_string ' (RUN ' num2str(i_i) ')' '''' ','];
                end
                for i=1:num_VCVS
                    interm_string=table_heading{1+num_Nodes+num_V+i};
                    interm_string=strrep(interm_string,'_','\_');
                    legend_current=[legend_current '''' interm_string ' (RUN ' num2str(i_i) ')' '''' ','];
                end
                for i=1:num_CCVS
                    interm_string=table_heading{1+num_Nodes+num_V+num_VCVS+i};
                    interm_string=strrep(interm_string,'_','\_');
                    legend_current=[legend_current '''' interm_string ' (RUN ' num2str(i_i) ')' '''' ','];
                end
                for i=1:num_L
                    interm_string=table_heading{1+num_Nodes+num_V+num_VCVS+num_CCVS+i};
                    interm_string=strrep(interm_string,'_','\_');
                    legend_current=[legend_current '''' interm_string ' (RUN ' num2str(i_i) ')' '''' ','];
                end
                if(i_i==runs)
                    legend_current(end)=')';
                    eval(legend_current);
                    xlabel('TIME (s)');
                    ylabel('CURRENTS (A)');
                end
            end
            if(i_i==runs) %If last run
                type('MC_values_ode.txt');  %Display the passive element values used at each run (display the contents of MC_values_ode.txt text file)
                fclose(G);  %Close MC_values_ode.txt text file
                figure(1);  %Save the graph(s)
                savefig('Voltages_graph.fig');
                if((num_V~=0)||(num_VCVS~=0)||(num_CCVS~=0)||(num_L~=0))
                    figure(2);
                    savefig('Currents_graph.fig');
                end
                warning(orig_state); %Restore the warning 'MATLAB:xlswrite:AddSheet' to its original state
            end
    end
end