within SiemensPowerOMCtest.Components.SolidComponents;
model Walllayer "Cylindrical metal tube (single layer)"
  import SI = Modelica.SIunits;

  constant Real pi=Modelica.Constants.pi;
  parameter Integer numberOfNodes(min=1)=2 "Number of nodes";
  parameter Boolean assumePlainHeatTransfer=false "no logarithmic correction"
                                annotation (Dialog(enable=considerConductivity));
  parameter SiemensPowerOMCtest.Utilities.Structures.PropertiesMetal metal
    "Wall metal properties"                                                      annotation (Dialog(enable=userdefinedmaterial, group="Material"));
  parameter Integer numberOfParallelTubes(min=1)=1 "Number of parallel tubes";
  parameter SI.Length length=1 "Tube length";
  parameter SI.Length diameterInner=0.08 "Internal diameter (single tube)";
  parameter SI.Length wallThickness=0.008 "Wall thickness";
  parameter Boolean useDynamicEquations=true
    "switch off for steady-state simulations" annotation (evaluate=true);

  parameter Boolean considerConductivity=true
    "Wall conduction resistance accounted for"                                           annotation (Evaluate=true);
  parameter Boolean considerAxialHeatTransfer=false
    "With heat transfer in the wall parallel to the flow direction"
          annotation (Evaluate=true, Dialog(enable=considerConductivity));
  parameter String initOpt="steadyState" "Initialisation option" annotation (Dialog(group="Initialization"),
  choices(
    choice="noInit" "No initial equations",
    choice="steadyState" "Steady-state initialization",
    choice="fixedTemperature" "Fixed-temperatures initialization"));

  parameter SI.Temperature T_start[numberOfNodes] "Temperature start values"       annotation (Dialog(group="Initialization"));

  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[numberOfNodes] port_ext(T(start = T_start))
    "Outer heat port"
    annotation (Placement(transformation(extent={{-16,20},{16,48}}, rotation=0)));                                                          //(T(start = linspace(Tstart1,TstartN,numberOfNodes)))
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b[numberOfNodes] port_int(T(start = T_start))
    "Inner heat port"
    annotation (Placement(transformation(extent={{-14,-48},{16,-20}}, rotation=
            0)));

  SI.Area Am "Area of the metal tube cross-section";
  SI.Temperature T[numberOfNodes](start=T_start) "Node temperatures";
  SI.Length rint;
  SI.Length rext;
  SI.Mass Tube_mass;
  SI.HeatCapacity HeatCap "HeatCapacity of a Tube part";

  SI.HeatFlowRate Q_flow_ax[numberOfNodes] "axial(parallel) heat transfer";

initial equation
  if initOpt == "noInit" then
 // nothing to do
  elseif initOpt == "steadyState" then
    der(T) = zeros(numberOfNodes);
  elseif initOpt == "fixedTemperature" then // fixed temperatures at start
    T = T_start;
  else
    assert(false, "Unsupported initialisation option");
  end if;

equation
  rint=diameterInner*0.5;
  rext=diameterInner*0.5+wallThickness;

 Tube_mass=(metal.rho*Am*length/numberOfNodes)* numberOfParallelTubes;
 HeatCap=metal.cp*Tube_mass;

  //  Energy balance
  for i in 1:numberOfNodes loop
    if (useDynamicEquations and wallThickness>0) then
        if (considerAxialHeatTransfer) then
           HeatCap*der(T[i]) = port_int[i].Q_flow + port_ext[i].Q_flow +  Q_flow_ax[i];
        else
           HeatCap*der(T[i]) = port_int[i].Q_flow + port_ext[i].Q_flow;
        end if;
    else
        if
          (considerAxialHeatTransfer) then
           0.0 = port_int[i].Q_flow + port_ext[i].Q_flow +  Q_flow_ax[i];
        else
           0.0 = port_int[i].Q_flow + port_ext[i].Q_flow;
        end if;
    end if;
  end for;

  Am = (rext^2-rint^2)*pi "Area of the metal cross section of single tube";
    if (considerConductivity and wallThickness>0) then
       for i in 1:numberOfNodes loop
            if assumePlainHeatTransfer then
                  port_int[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_int[i].T-T[i])*2/(rext/rint-1);
                  port_ext[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_ext[i].T -T[i])*2/(1-rint/rext);
            else
                  port_int[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_int[i].T-T[i])/(Modelica.Math.log((rext+rint)/(2*rint)));
                  port_ext[i].Q_flow = metal.lambda*2*pi*length/numberOfNodes*numberOfParallelTubes*(port_ext[i].T -T[i])/(Modelica.Math.log((2*rext)/(rint + rext)));
            end if;
       end for;
       if (considerAxialHeatTransfer) then
            Q_flow_ax[1] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[2]-T[1]);
            for i in 2:(numberOfNodes-1) loop
              Q_flow_ax[i] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[i-1]-2*T[i]+T[i+1]);
            end for;
            Q_flow_ax[numberOfNodes] = metal.lambda*Am*numberOfParallelTubes/(length/numberOfNodes)*(T[numberOfNodes-1]-T[numberOfNodes]);
       else
            Q_flow_ax = zeros(numberOfNodes);
       end if;
    else
      // No temperature gradients across the thickness
      port_int.T = T;
      port_ext.T = T;
      Q_flow_ax = zeros(numberOfNodes);
    end if;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics={
        Rectangle(
          extent={{-80,20},{80,-20}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-84,-22},{-32,-50}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Int"),
        Text(
          extent={{-82,50},{-34,24}},
          lineColor={0,0,0},
          fillColor={128,128,128},
          fillPattern=FillPattern.Forward,
          textString="Ext"),
        Text(
          extent={{-100,-60},{100,-88}},
          lineColor={191,95,0},
          textString="%name")}),
                           Documentation(info="<HTML>
<p>This is the model of a cylindrical tube layer of solid material.
<p>The heat capacity (which is lumped at the center of the tube thickness) is accounted for, as well as the thermal resistance due to the finite heat conduction coefficient. Longitudinal heat conduction is neglected.
<p><b>Modelling options</b></p>
<p>The following options are available to specify the valve flow coefficient in fully open conditions:
<ul>
<li><tt>considerConductivity = false</tt>: the thermal resistance of the tube wall is neglected.
<li><tt>considerConductivity = true</tt>: the thermal resistance of the tube wall is accounted for.
</ul>
</HTML>
<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                           <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>

                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
        revisions="<html>
<ul>
<li> December 2006, adapted to SiemensPower by Haiko Steuer
<li><i>30 May 2005</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       Initialisation support added.</li>
<li><i>1 Oct 2003</i>
    by <a href=\"mailto:francesco.casella@polimi.it\">Francesco Casella</a>:<br>
       First release.</li>
</ul>
</html>
"));
end Walllayer;