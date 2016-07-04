// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//	 		 	 	  				  		   			  						
// Major Functions:	control processor's datapath
// 
// Input(s):	1. instr: input is used to determine states
//				2. N: if branches, input is used to determine if
//					  negative condition is true
//				3. Z: if branches, input is used to determine if 
//					  zero condition is true
//
// Output(s):	control signals
//
//				** More detail can be found on the course note under
//				   "Multi-Cycle Implementation: The Control Unit"
//
// ---------------------------------------------------------------------

module FSM
(
reset, instr, clock,
N, Z,
PCwrite, AddrSel, MemRead,
MemWrite, IRload, OpASel, MDRload,
OpABLoad, ALU1, ALU2, ALUop,
ALUOutWrite, RFWrite, RegIn, FlagWrite,//, state
MDRsel 
);
	input	[3:0] instr;
	input	N, Z;
	input	reset, clock;
	output	PCwrite, AddrSel, MemRead, MemWrite, IRload, OpASel, MDRload;
	output	OpABLoad, ALU1, ALUOutWrite, RFWrite, RegIn, FlagWrite;
	//add one more control 
	output MDRsel;
	output	[2:0] ALU2, ALUop;
	//output	[3:0] state;
	
	reg [4:0]	state;			// 5-bit state can encode 32 distinct values.
	reg	PCwrite, AddrSel, MemRead, MemWrite, IRload, OpASel, MDRload, MDRsel;
	reg	OpABLoad, ALU1, ALUOutWrite, RFWrite, RegIn, FlagWrite;
	reg	[2:0] ALU2, ALUop;
	
	
	// state constants (note: asn = add/sub/nand, asnsh = add/sub/nand/shift)
	parameter [4:0] reset_s = 0, c1 = 1, c2 = 2, c3_asn = 3,
					c4_asnsh = 4, c3_shift = 5, c3_ori = 6,
					c4_ori = 7, c5_ori = 8, c3_load = 9, c4_load = 10,
					c3_store = 11, c3_bpz = 12, c3_bz = 13, c3_bnz = 14,
					c3_jr = 15, c3_jal = 16, c4_jal = 17, c5_jal = 18,c6_jal =19,
					c3_ldind = 20, c4_ldind = 21, c5_ldind =22;
	
	// determines the next state based on the current state; supports
	// asynchronous reset
	always @(posedge clock or posedge reset)
	begin
		if (reset) state = reset_s;
		else
		begin
			case(state)
				reset_s:	state = c1; 		// reset state
				c1:			state = c2; 		// cycle 1
				c2:			begin				// cycle 2
								if(instr == 4'b0100 | instr == 4'b0110 | instr == 4'b1000) state = c3_asn;
								else if( instr[2:0] == 3'b011 ) state = c3_shift;
								else if( instr[2:0] == 3'b111 ) state = c3_ori;
								else if( instr == 4'b0000 ) state = c3_load;
								else if( instr == 4'b0010 ) state = c3_store;
								else if( instr == 4'b1101 ) state = c3_bpz;
								else if( instr == 4'b0101 ) state = c3_bz;
								else if( instr == 4'b1001 ) state = c3_bnz;
								//add new states
								else if( instr == 4'b1110) state = c3_jr; //jump register
								else if( instr == 4'b1100) state = c3_jal; //JAL, jump and link
								else if( instr ==  4'b0001) state = c3_ldind; //LDIND. Load indirect
								
								else state = 0;
							end
				c3_asn:		state = c4_asnsh;	// cycle 3: ADD SUB NAND
				c4_asnsh:	state = c1;			// cycle 4: ADD SUB NAND/SHIFT
				c3_shift:	state = c4_asnsh;	// cycle 3: SHIFT
				c3_ori:		state = c4_ori;		// cycle 3: ORI
				c4_ori:		state = c5_ori;		// cycle 4: ORI
				c5_ori:		state = c1;			// cycle 5: ORI
				c3_load:	state = c4_load;	// cycle 3: LOAD
				c4_load:	state = c1; 		// cycle 4: LOAD
				c3_store:	state = c1; 		// cycle 3: STORE
				c3_bpz:		state = c1; 		// cycle 3: BPZ
				c3_bz:		state = c1; 		// cycle 3: BZ
				c3_bnz:		state = c1; 		// cycle 3: BNZ
				//add lab7
				//JR
				c3_jr: state = c1;
				//JAL
				c3_jal: state = c4_jal;
				c4_jal: state = c5_jal;
				c5_jal:  state = c6_jal;
				c6_jal: state = c1; //done, go reset
//				
				//LDIND
				c3_ldind: state = c4_ldind;
				c4_ldind: state = c5_ldind;
				c5_ldind: state = c1; //reset
			endcase
		end
	end

	// sets the control sequences based on the current state and instruction
	always @(*)
	begin
		case (state)
			reset_s:	//control = 19'b0000000000000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
					MDRsel = 0;
				end					
			c1: 		//control = 19'b1110100000010000000;
				begin
					PCwrite = 1;
					AddrSel = 1;
					MemRead = 1;
					MemWrite = 0;
					IRload = 1;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b001;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
					MDRsel =0;
				end	
			c2: 		//control = 19'b0000000100000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 1;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0; 
					MDRsel =0; //still let OPA/R1 go through
				end
			c3_asn:		begin
							if ( instr == 4'b0100 ) 		// add
								//control = 19'b0000000010000001001;
							begin
								PCwrite = 0;
								AddrSel = 0;
								MemRead = 0;
								MemWrite = 0;
								IRload = 0;
								OpASel = 0;
								MDRload = 0;
								OpABLoad = 0;
								ALU1 = 1;
								ALU2 = 3'b000;
								ALUop = 3'b000;
								ALUOutWrite = 1;
								RFWrite = 0;
								RegIn = 0;
								FlagWrite = 1;
								MDRsel =0; //still let OPA/R1 go through

							end	
							else if ( instr == 4'b0110 ) 	// sub
								//control = 19'b0000000010000011001;
							begin
								PCwrite = 0;
								AddrSel = 0;
								MemRead = 0;
								MemWrite = 0;
								IRload = 0;
								OpASel = 0;
								MDRload = 0;
								OpABLoad = 0;
								ALU1 = 1;
								ALU2 = 3'b000;
								ALUop = 3'b001;
								ALUOutWrite = 1;
								RFWrite = 0;
								RegIn = 0;
								FlagWrite = 1;
					MDRsel =0; //still let OPA/R1 go through
								
							end
							else 							// nand
								//control = 19'b0000000010000111001;
							begin
								PCwrite = 0;
								AddrSel = 0;
								MemRead = 0;
								MemWrite = 0;
								IRload = 0;
								OpASel = 0;
								MDRload = 0;
								OpABLoad = 0;
								ALU1 = 1;
								ALU2 = 3'b000;
								ALUop = 3'b011;
								ALUOutWrite = 1;
								RFWrite = 0;
								RegIn = 0;
								FlagWrite = 1;
											MDRsel =0; //still let OPA/R1 go through

							end
				   		end
			c4_asnsh: 	//control = 19'b0000000000000000100;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 1;
					RegIn = 0;
					FlagWrite = 0;
					
								MDRsel =0; //still let OPA/R1 go through

				end
			c3_shift: 	//control = 19'b0000000011001001001;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 1;
					ALU2 = 3'b100;
					ALUop = 3'b100;
					ALUOutWrite = 1;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 1;
					
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_ori: 	//control = 19'b0000010100000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 1;
					MDRload = 0;
					OpABLoad = 1;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c4_ori: 	//control = 19'b0000000010110101001;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 1;
					ALU2 = 3'b011;
					ALUop = 3'b010;
					ALUOutWrite = 1;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 1;
										MDRsel =0; //still let OPA/R1 go through

				end
			c5_ori: 	//control = 19'b0000010000000000100;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 1;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 1;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_load: 	//control = 19'b0010001000000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 1;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 1;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c4_load: 	//control = 19'b0000000000000001110;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 1;
					RFWrite = 1;
					RegIn = 1;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_store: 	//control = 19'b0001000000000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 1;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_bpz: 	//control = {~N,18'b000000000100000000};
				begin
					PCwrite = ~N;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_bz: 		//control = {Z,18'b000000000100000000};
				begin
					PCwrite = Z;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
			c3_bnz: 	//control = {~Z,18'b000000000100000000};
				begin
					PCwrite = ~Z;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

				end
				
			//add JR control signals
			c3_jr: // MDR = mem[R2]
			begin
					PCwrite = 1;
					AddrSel = 0;
					MemRead = 1;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 1; 
					ALU2 = 3'b101; //give ALU 0
					ALUop = 3'b000; //op = add
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
										MDRsel =0; //still let OPA/R1 go through

			end
			
			//JAL
			c3_jal: //PC+1 to PC
			begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0; //get PC
					ALU2 = 3'b101; //get im 0
					ALUop = 3'b000; //do add
					ALUOutWrite = 1; //go to alu_reg
					RFWrite = 0;
					RegIn = 0; //chooses ALUout
					FlagWrite = 0;
					MDRsel =0; //still let OPA/R1 go through

			end
			
			c4_jal: //PC to R1
			begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 1; //leave it there
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0; //take the PC +1 directly
					ALU2 = 3'b000;  //010, IMM4
					ALUop = 3'b000; //add
					ALUOutWrite = 0; //keep pc + 1
					RFWrite = 1;
					RegIn = 0; //chooses ALUoutReg
					FlagWrite = 0;
					MDRsel =0; //still let OPA/R1 go through
				
			end
			
			c5_jal: //get pc + 1  + IMM4 -> PC
			begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 1;
					MDRload = 0;
					OpABLoad = 1;
					ALU1 = 0; //take pc directly
					ALU2 = 3'b000; //selec imm4
					ALUop = 3'b000; //add
					ALUOutWrite = 0; //go directly to PC?
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;			
			end

			
			c6_jal: //get pc + 1  + IMM4 -> PC
			begin
					PCwrite = 1;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 1; //take pc directly
					ALU2 = 3'b010; //selec imm4
					ALUop = 3'b000; //add
					ALUOutWrite = 0; //go directly to PC?
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;			
			end
//			c7_jal: //get pc + 1  + IMM4 -> PC
//			begin
//					PCwrite = 1;
//					AddrSel = 0;
//					MemRead = 0;
//					MemWrite = 0;
//					IRload = 0;
//					OpASel = 0;
//					MDRload = 0;
//					OpABLoad = 0;
//					ALU1 = 0; //take pc directly
//					ALU2 = 3'b000; //selec imm4
//					ALUop = 3'b000; //add
//					ALUOutWrite = 0; //go directly to PC?
//					RFWrite = 0;
//					RegIn = 0;
//					FlagWrite = 0;			
//			end
			c3_ldind: //read 1st
			begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 1;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 1;
					OpABLoad = 1;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
					MDRsel =0; //still let OPA/R1 go through			
			
			end
			
			c4_ldind: //read 2nd
			begin
					PCwrite = 0;
					AddrSel = 2; //fetch the read addr
					MemRead = 1;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0; 
					MDRload = 1;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
					MDRsel =1; //still let OPA/R1 go through			
			
			end			
		
		c5_ldind: //go to R1
			begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 1;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 1;
					RegIn = 1;
					FlagWrite = 0;
					MDRsel =0; //still let OPA/R1 go through			
			
			end
			default:	//control = 19'b0000000000000000000;
				begin
					PCwrite = 0;
					AddrSel = 0;
					MemRead = 0;
					MemWrite = 0;
					IRload = 0;
					OpASel = 0;
					MDRload = 0;
					OpABLoad = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALUOutWrite = 0;
					RFWrite = 0;
					RegIn = 0;
					FlagWrite = 0;
					MDRsel =0; //still let OPA/R1 go through

				end
		endcase
	end
	
endmodule 	  	 	 		    		  			   		      
                   
