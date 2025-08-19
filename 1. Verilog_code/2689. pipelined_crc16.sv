module pipelined_crc16(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    reg [15:0] stage1, stage2, stage3;
    
    always @(posedge clk) begin
        if (rst) begin
            stage1 <= 16'hFFFF;
            stage2 <= 16'hFFFF;
            stage3 <= 16'hFFFF;
            crc_out <= 16'hFFFF;
        end else if (data_valid) begin
            stage1 <= {stage1[14:0], 1'b0} ^ ((stage1[15] ^ data_in[7]) ? POLY : 16'h0);
            stage2 <= {stage1[14:0], 1'b0} ^ ((stage1[15] ^ data_in[6]) ? POLY : 16'h0);
            stage3 <= {stage2[14:0], 1'b0} ^ ((stage2[15] ^ data_in[5]) ? POLY : 16'h0);
            crc_out <= {stage3[14:0], 1'b0} ^ ((stage3[15] ^ data_in[4]) ? POLY : 16'h0);
        end
    end
endmodule