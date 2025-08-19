module two_stage_decoder (
    input [3:0] address,
    output [15:0] select
);
    wire [3:0] stage1_out;
    
    // First stage decodes top 2 bits
    assign stage1_out = (4'b0001 << address[3:2]);
    
    // Second stage uses bottom 2 bits
    assign select[3:0]   = address[1:0] == 2'b00 ? {3'b000, stage1_out[0]} : 4'b0000;
    assign select[7:4]   = address[1:0] == 2'b01 ? {3'b000, stage1_out[1]} : 4'b0000;
    assign select[11:8]  = address[1:0] == 2'b10 ? {3'b000, stage1_out[2]} : 4'b0000;
    assign select[15:12] = address[1:0] == 2'b11 ? {3'b000, stage1_out[3]} : 4'b0000;
endmodule