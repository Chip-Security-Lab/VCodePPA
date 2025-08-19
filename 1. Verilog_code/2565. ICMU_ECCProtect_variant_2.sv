//SystemVerilog
module ICMU_ECCProtect #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_sync,
    input [DATA_WIDTH-1:0] data_in,
    input ctx_write,
    output [DATA_WIDTH-1:0] data_out,
    output reg ecc_error
);

    reg [DATA_WIDTH+ECC_WIDTH-1:0] mem;
    wire [ECC_WIDTH-1:0] ecc_gen;
    wire [ECC_WIDTH-1:0] ecc_check;
    wire ecc_mismatch;

    // 组合逻辑：ECC生成
    function [ECC_WIDTH-1:0] calc_ecc;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_ecc = ^{data[63:0], 8'h00};
        end
    endfunction

    // 组合逻辑：ECC生成和校验
    assign ecc_gen = calc_ecc(data_in);
    assign ecc_check = calc_ecc(mem[DATA_WIDTH-1:0]);
    assign ecc_mismatch = (ecc_check != mem[DATA_WIDTH+ECC_WIDTH-1:DATA_WIDTH]);
    assign data_out = mem[DATA_WIDTH-1:0];

    // 时序逻辑：存储和错误检测
    always @(posedge clk) begin
        if (rst_sync) begin
            mem <= 0;
            ecc_error <= 0;
        end else if (ctx_write) begin
            mem <= {ecc_gen, data_in};
        end else begin
            ecc_error <= ecc_mismatch;
        end
    end

endmodule