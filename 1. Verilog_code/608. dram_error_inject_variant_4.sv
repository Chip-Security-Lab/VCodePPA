//SystemVerilog
module dram_error_inject #(
    parameter ERROR_MASK = 8'hFF
)(
    input clk,
    input rst_n,
    input enable,
    input [63:0] data_in,
    output reg [63:0] data_out,
    output reg valid_out
);

    reg [63:0] data_stage1, data_stage2, data_stage3, data_stage4;
    reg enable_stage1, enable_stage2, enable_stage3;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 64'h0;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            data_stage2 <= 64'h0;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            data_stage3 <= 64'h0;
            enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            data_stage4 <= 64'h0;
            valid_stage4 <= 1'b0;
            data_out <= 64'h0;
            valid_out <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            enable_stage1 <= enable;
            valid_stage1 <= 1'b1;
            data_stage2 <= data_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            data_stage3 <= enable_stage2 ? {8{ERROR_MASK}} : 64'h0;
            enable_stage3 <= enable_stage2;
            valid_stage3 <= valid_stage2;
            data_stage4 <= enable_stage3 ? (data_stage2 ^ data_stage3) : data_stage2;
            valid_stage4 <= valid_stage3;
            data_out <= data_stage4;
            valid_out <= valid_stage4;
        end
    end

endmodule