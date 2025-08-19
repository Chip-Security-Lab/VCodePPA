module multistage_shifter(
    input [7:0] data_in,
    input [2:0] shift_amt,
    output [7:0] data_out
);
    // Multi-stage implementation using intermediate wires
    wire [7:0] stage0_out, stage1_out;
    
    // Stage 0: Shift by 0 or 1 bit
    assign stage0_out = shift_amt[0] ? {data_in[6:0], 1'b0} : data_in;
    
    // Stage 1: Shift by 0 or 2 bits
    assign stage1_out = shift_amt[1] ? {stage0_out[5:0], 2'b00} : stage0_out;
    
    // Stage 2: Shift by 0 or 4 bits
    assign data_out = shift_amt[2] ? {stage1_out[3:0], 4'b0000} : stage1_out;
    
    // This logarithmic approach is more efficient for hardware
    // implementation than a single large shifter
endmodule