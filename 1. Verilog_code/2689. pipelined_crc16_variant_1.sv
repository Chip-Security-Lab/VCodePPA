//SystemVerilog
module pipelined_crc16(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    reg [15:0] stage1, stage2, stage3;
    wire [15:0] stage1_next, stage2_next, stage3_next, crc_next;
    wire [3:0] msb_xor;
    
    assign msb_xor = {stage1[15], stage2[15], stage3[15], stage3[15]} ^ data_in[7:4];
    
    assign stage1_next = {stage1[14:0], 1'b0} ^ (msb_xor[3] ? POLY : 16'h0);
    assign stage2_next = {stage1[14:0], 1'b0} ^ (msb_xor[2] ? POLY : 16'h0);
    assign stage3_next = {stage2[14:0], 1'b0} ^ (msb_xor[1] ? POLY : 16'h0);
    assign crc_next = {stage3[14:0], 1'b0} ^ (msb_xor[0] ? POLY : 16'h0);
    
    always @(posedge clk) begin
        if (rst) begin
            stage1 <= 16'hFFFF;
            stage2 <= 16'hFFFF;
            stage3 <= 16'hFFFF;
            crc_out <= 16'hFFFF;
        end else if (data_valid) begin
            stage1 <= stage1_next;
            stage2 <= stage2_next;
            stage3 <= stage3_next;
            crc_out <= crc_next;
        end
    end
endmodule