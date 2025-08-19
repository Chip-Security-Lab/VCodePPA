//SystemVerilog
module pipelined_crossbar (
    input wire clock, reset,
    input wire [15:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output wire [15:0] out0, out1, out2, out3
);
    // Forward register retiming - moved registers through combinational logic
    // First stage directly selects input based on select signals
    reg [15:0] mux_out0, mux_out1, mux_out2, mux_out3;
    
    // Selection logic moved before registers
    wire [15:0] sel_in0, sel_in1, sel_in2, sel_in3;
    
    // Combinational input selection moved before registers
    assign sel_in0 = (sel0 == 2'b00) ? in0 :
                     (sel0 == 2'b01) ? in1 :
                     (sel0 == 2'b10) ? in2 : in3;
                     
    assign sel_in1 = (sel1 == 2'b00) ? in0 :
                     (sel1 == 2'b01) ? in1 :
                     (sel1 == 2'b10) ? in2 : in3;
                     
    assign sel_in2 = (sel2 == 2'b00) ? in0 :
                     (sel2 == 2'b01) ? in1 :
                     (sel2 == 2'b10) ? in2 : in3;
                     
    assign sel_in3 = (sel3 == 2'b00) ? in0 :
                     (sel3 == 2'b01) ? in1 :
                     (sel3 == 2'b10) ? in2 : in3;
    
    // Single pipeline stage - registers moved after combinational logic
    reg [15:0] out_reg0, out_reg1, out_reg2, out_reg3;
    
    // Pipeline stage with optimized register placement
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            out_reg0 <= 16'h0000;
            out_reg1 <= 16'h0000;
            out_reg2 <= 16'h0000;
            out_reg3 <= 16'h0000;
        end else begin
            out_reg0 <= sel_in0;
            out_reg1 <= sel_in1;
            out_reg2 <= sel_in2;
            out_reg3 <= sel_in3;
        end
    end
    
    // Direct output assignments
    assign out0 = out_reg0;
    assign out1 = out_reg1;
    assign out2 = out_reg2;
    assign out3 = out_reg3;
endmodule