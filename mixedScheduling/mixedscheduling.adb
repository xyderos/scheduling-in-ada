-- FIFO for priorities 2-30
pragma Priority_Specific_Dispatching( FIFO_Within_Priorities, 2, 30);

-- Round robin for low priority value of 1 only
pragma Priority_Specific_Dispatching( Round_Robin_Within_Priorities, 1, 1);

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Float_Text_IO;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;

with Ada.Real_Time; use Ada.Real_Time;

procedure MixedScheduling is
   
   package Duration_IO is new Ada.Text_IO.Fixed_IO(Duration);
   
   package Int_IO is new Ada.Text_IO.Integer_IO(Integer);
	
    Start : constant Time := Clock; -- Start Time of the System
	
    Calibrator: constant Integer := 1208; -- Calibration for correct timing
	
    Warm_Up_Time: constant Integer := 100; -- Warmup time in milliseconds

    HyperperiodLength: Time_Span := Milliseconds(1200);
    
    CurrentHyperperiod: Integer := 1;
    
    NextHyperperiod: Time:= Start + HyperperiodLength + Milliseconds(Warm_Up_Time);
	
	-- Conversion Function: Time_Span to Float
	function To_Float(TS : Time_Span) return Float is
    
        SC : Seconds_Count;
    
        Frac : Time_Span;
  
   begin

		Split(Time_Of(0, TS), SC, Frac);

		return Float(SC) + Time_Unit * Float(Frac/Time_Span_Unit);

   end To_Float;
	
	-- Function F is a dummy function that is used to model a running user program.
	function F(N : Integer) return Integer;

   function F(N : Integer) return Integer is

      X : Integer := 0;

   begin

      for Index in 1..N loop

         for I in 1..500 loop

            X := X + I;

         end loop;

      end loop;

      return X;

   end F;
	
	-- Workload Model for a Parametric Task
    task type T(Id: Integer; Prio: Integer; Phase: Integer; Period : Integer; 

        Computation_Time : Integer; Relative_Deadline: Integer; Color : Integer) is

        pragma Priority(Prio); -- A higher number gives a higher priority
    end;

   task body T is

      Next : Time;

		Release: Time;

		Completed : Time;

		Response : Time_Span;

		Average_Response : Float;

		Absolute_Deadline: Time;

		WCRT: Time_Span; -- measured WCRT (Worst Case Response Time)

        Dummy : Integer;

		Iterations : Integer;

        Released: Time;

        ColorCode : String := "[" & Trim(Color'Img, Ada.Strings.Left) & "m";

   begin
		-- Initial Release - Phase
		Release := Clock + Milliseconds(Phase);

		delay until Release;

		Next := Release;

		Iterations := 0;

		Average_Response := 0.0;

		WCRT := Milliseconds(0);

      loop

        Next := Release + Milliseconds(Period);
        
        Released := Clock;
    
        if (Release > NextHyperperiod) then
    
            NextHyperperiod := NextHyperperiod + HyperperiodLength;
        
            CurrentHyperperiod := CurrentHyperperiod + 1;
        
            New_Line(1);
        
        end if;
		
        Absolute_Deadline := Release + Milliseconds(Relative_Deadline);
		
    	for I in 1..Computation_Time loop
		
    		Dummy := F(Calibrator);         	
        
        end loop;	
		
        Completed := Clock;
		
        Response := Completed - Release;
		
        Average_Response := (Float(Iterations) * Average_Response + To_Float(Response)) / Float(Iterations + 1);
		
        if Response > WCRT then
		
    		WCRT := Response;
		
    	end if;
        
        Put(ASCII.ESC & ColorCode);
	
    	Iterations := Iterations + 1;			
		
        Put("H: ");
		
        Int_IO.Put(CurrentHyperperiod, 1);
		
        Put(" Task: ");
	
    	Int_IO.Put(Id, 1);

        Put(" Period: " );
        
        Int_IO.Put(Period, 1);
		
        Put(", Release: ");
		
        Duration_IO.Put(To_Duration(Release - Start), 2, 3);
		
        Put(", Released: ");
		
        Duration_IO.Put(To_Duration(Released - Start), 2, 3);
		
        Put(", Completion: ");
		
        Duration_IO.Put(To_Duration(Completed - Start), 2, 3);
		
        Put(", Response: ");
		
        Duration_IO.Put(To_Duration(Response), 1, 3);
		
        Put(", WCRT: ");
		
        Ada.Float_Text_IO.Put(To_Float(WCRT), fore => 1, aft => 3, exp => 0);	
		
        Put(", Next Release: ");
		
        Duration_IO.Put(To_Duration(Next - Start), 2, 3);
		
        if Completed > Absolute_Deadline then 
			
            Put(" ==> Task ");
		
        	Int_IO.Put(Id, 1);
	
    		Put(" violates Deadline! ");
		end if;
        
        Put(ASCII.ESC & "[00m");
        
        New_Line(1);
		
        Release := Next;
        
        delay until Release;

    end loop;

end T;

    --set period as 0 so it will always try to execute next
   Task_1 : T(1, 20, Warm_Up_Time, 300, 100, 300, 33); -- ID: 1

   Task_2 : T(2, 18, Warm_Up_Time, 400, 100, 400, 31); -- ID: 2

   Task_3 : T(3, 16, Warm_Up_Time, 600, 100, 600, 32); -- ID: 3

   Task_4 : T(4, 1, Warm_Up_Time, 0, 100, 300, 0); -- ID: 4

   Task_5 : T(5, 1, Warm_Up_Time, 0, 100, 300, 0); -- ID: 5

   Task_6 : T(6, 1, Warm_Up_Time, 0, 100, 300, 0); -- ID: 6
	
begin
   null;
end MixedScheduling;