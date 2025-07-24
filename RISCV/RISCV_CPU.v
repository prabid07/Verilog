`timescale 1ns / 1ps

// pc counter in rics v it has only one input and one output line as shown in architecture
module program_counter #(parameter n = 32) (
input clk, reset,
input [n-1:0] pc_in,
output reg [n-1:0] pc_out );

always @(posedge clk or posedge reset)
begin 
if(reset)
    pc_out <= 00;
else 
    pc_out <= pc_in;
end
endmodule

// pc adder it increments the program counter

module pc4adder #(parameter n=32) (
input [n-1:0] from_pc,
output  [n-1:0] next_pc   );

assign next_pc= 4 + from_pc;
endmodule

// instruction memory 
module instruction_mem #(parameter n = 32, parameter p=64)(
input clk, reset,
input [n-1:0]read_address,
output reg [n-1:0] instruction_out );

integer k;
reg [n-1:0] Instruction_memory [p-1:0];
always @(posedge clk or posedge reset )
begin 
if(reset)
 begin 
 for (k=0; k<64; k=k+1)
    Instruction_memory[k] <=00;
 end 
 else
 instruction_out <= Instruction_memory[read_address];
end
endmodule 


// registetr file 

module reg_file #(parameter n=32)(
input clk, reset, reg_write,
input [4:0] Rs1, Rs2, Rd,
input [n-1:0] write_data,
output [n-1:0] read_data1, read_data2  );
integer k;
reg [n-1:0] registers[n-1:0];
always @(posedge clk or posedge reset)
begin 
 if (reset)
    begin 
        for (k=0; k < n; k = k+1)
        begin 
        registers[k]=00;
        end 
        end
else if (reg_write)
begin 
registers [Rd] <= write_data;
end 
end
assign read_data1= registers[Rs1];
assign read_data = registers[Rs2];
endmodule  


// immediate generator used to generate immediate opcode

module immgen #(parameter n=32)(opcode, instruction, immext);
input [6:0]opcode;
input [n-1:0]instruction;
output reg [n-1:0]immext;
always@(*)
begin
case(opcode)
7'b0000011 : immext = {{20{instruction[31]}},instruction[31:20]};
7'b0100011 : immext = {{20{instruction[31]}},instruction[31:25],instruction[11:7]};
7'b1100011 : immext = {{19{instruction[31]}},instruction[31],instruction[30:25], instruction[11:8],1'b0};
endcase
end
endmodule



// module control unit
module control_unit(instruction, branch, memread,memtoreg, aluop, memwrite, alusrc,regwrite);
input [6:0]instruction;
output reg branch, memread, memtoreg, memwrite, alusrc, regwrite;
output reg [1:0] aluop;
always@(*)
begin
case(instruction)
7'b0110011: {alusrc,memtoreg, regwrite, memread, memwrite, branch, aluop} <= 8'b001000_01 ;
7'b0000011: {alusrc,memtoreg, regwrite, memread, memwrite, branch, aluop} <= 8'b111100_00;
7'b0100011: {alusrc,memtoreg, regwrite, memread, memwrite, branch, aluop} <= 8'b100010_00;
7'b1100011: {alusrc,memtoreg, regwrite, memread, memwrite, branch, aluop} <= 8'b000001_01;
endcase
end
endmodule


// creating an alu and opcode

module alu_unit(a,b,control_in,alu_result,zero);
input [31:0] a,b;
input [3:0] control_in;
output reg zero;
output reg [31:0] alu_result;
always@(control_in  or a or b)
begin 
case(control_in)
4'b0000: begin zero <=0; alu_result <= a &b; end
4'b0001: begin zero <= 0; alu_result <= a |b; end
4'b0010: begin zero <= 0; alu_result <= a +b; end
4'b0110 : begin if (a==b) zero <=1; else zero <= 0; alu_result = a-b ; end
endcase
end
endmodule


// desigining an alu control unit
module alu_control(aluop, fun7, fun3, control_unit);
input fun7;
input [2:0] fun3;
input [1:0] aluop;
output reg [3:0] control_unit;
always@(*)
begin 
case({aluop,fun7, fun3})
6'b00_0_000: control_unit<= 4'b0010;
6'b01_0_00: control_unit <= 4'b0110;
6'b10_0_000: control_unit <=4'b0010;
6'b10_1_000: control_unit <= 4'b0110;
6'b10_0_111: control_unit<= 4'b0000;
6'b10_0_110: control_unit <=4'b0001;
endcase
end
endmodule


// data memory read and write
module data_mem(clk, reset, memwrite, memread, read_address, write_data, memdata_out);
input clk, reset, memwrite, memread;
input [31:0] read_address, write_data;
output [31:0] memdata_out;
reg [31:0] d_memory[63:0];
integer k;
always @(posedge clk)
begin
if (reset)
for (k=0; k<64; k=k+1)
begin
d_memory[k]=32'b0;
end
else if(memwrite)
begin
d_memory[read_address] <= write_data;
end
end
assign memdata_out=(memread)?d_memory[read_address]:32'b00;
endmodule

// alu multiplexer

module mux1(sel1,a1,b1, mux1_out);
input sel1;
input [31:0] a1,b1;
output [31:0] mux1_out;
assign mux1_out=(sel1==1'b0)? a1 : b1;
endmodule
// mux2
module mux2(sel2,a2,b2, mux2_out);
input sel2;
input [31:0] a2,b2;
output [31:0] mux2_out;
assign mux2_out=(sel2==1'b0)? a2 : b2;
endmodule
// mux 3
module mux3(sel3,a3,b3, mux3_out);
input sel3;
input [31:0] a3,b3;
output [31:0] mux3_out;
assign mux3_out=(sel3==1'b0)? a3 : b3;
endmodule

// and logic gates
module AND_logic(branch, zero, and_out);
input branch, zero;
output and_out;
assign and_out = branch & zero;
endmodule


//adder module 
module adder(in_1, in_2, sum_out);
input [31:0] in_1, in_2;
output [31:0] sum_out;
assign sum_out= in_1+in_2;
endmodule


// instantiating all module here
module top(clk, reset);
input clk, reset;

wire [31:0] pc_top, instruction_top,rd1_top, rd2_top, immext_top,address_top, mux1_top, sumout_top, nextopc_top, pcin_top, mem_data, writedataback_top;
wire memread_top, regwire_top, alusrc_top, zero_top, branch_top, selmux_top, memtoreg_top, memwrite_top;
wire [1:0] aluop_top;

wire [3:0]control_top;

// program counter
program_counter PC ( .clk(clk), .reset(reset), .pc_in(pcin_top), .pc_out(pc_top) );
//pc adder
pc4adder PC_Adder(.from_pc(pc_top), .next_pc(nextopc_top));
// instruction memory
instruction_mem Ins_Mem( .clk(clk), .reset(reset),  .read_address(pc_top), .instruction_out(instruction_top) );
// register file
reg_file Reg_File( .clk(clk), .reset(reset), .reg_write(regwrite_top), .Rs1(instruction_top[19:15]), .Rs2(instruction_top[24:20]), .Rd(instruction_top[11:7]),  .write_data(writedataback_top), .read_data1(rd1_top), .read_data2(rd2_top)  );
// immediate generator
immgen Imm_Gen(.opcode(instruction_top[6:0]), .instruction(instruction_top), .immext(immext_top));
// control unit module
control_unit Control_Unit(.instruction(instruction_top[6:0]), .branch(branch_top), .memread(memread_top), .memtoreg(memtoreg_top), .aluop(aluop_top), .memwrite(memwrite_top), .alusrc(alusrc_top),.regwrite(regwire_top) );
// alu control unit 
 alu_control ALU_Control(.aluop(aluop_top), .fun7(instruction_top[30]), .fun3(instruction_top[14:12]), .control_unit(control_top));
// alu unit
alu_unit ALU_Unit(.a(rd1_top),.b(),.control_in(control_top),.alu_result(address_top),.zero());
// alu mux
mux1 Mux1(.sel1(alusrc_top),.a1(rd2_top),.b1(immext_top), .mux1_out(rd2_top));
// adder ckt 
adder Adder (.in_1(), .in_2(immext_top), .sum_out(sumout_top));
// and gate
AND_logic AndGate(.branch(branch_top), .zero(zero_top), .and_out(selmux_top));
// mux 2
mux2 Addermux(.sel2(selmux_top), .a2(nextopc_top), .b2(sumout_top), .mux2_out(pcin_top));
// data memory
data_mem Data_mem(.clk(clk), .reset(reset), .memwrite(memwrite_top), .memread(memread_top), .read_address(address_top), .write_data(rd2_top), .memdata_out(memdata_top));
// mux3
mux3 data_mux(.sel3(memtoreg_top),.a3(address_top),.b3(memdata_top), .mux3_out(writebackdata_top));

endmodule