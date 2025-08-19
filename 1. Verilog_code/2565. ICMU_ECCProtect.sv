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
    
    // Hamming(72,64) ECC生成
    function [ECC_WIDTH-1:0] calc_ecc;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_ecc = ^{data[63:0], 8'h00};
        end
    endfunction
    
    always @(posedge clk) begin
        if (rst_sync) begin
            mem <= 0;
            ecc_error <= 0;
        end else if (ctx_write) begin
            mem <= {calc_ecc(data_in), data_in};
        end else begin
            ecc_error <= (calc_ecc(mem[DATA_WIDTH-1:0]) != mem[DATA_WIDTH+ECC_WIDTH-1:DATA_WIDTH]);
        end
    end
    
    assign data_out = mem[DATA_WIDTH-1:0];
endmodule
