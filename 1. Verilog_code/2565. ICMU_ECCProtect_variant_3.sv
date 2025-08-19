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
    wire [ECC_WIDTH-1:0] current_ecc;
    wire [ECC_WIDTH-1:0] stored_ecc;
    wire [DATA_WIDTH+ECC_WIDTH-1:0] mem_plus_one;
    wire [DATA_WIDTH+ECC_WIDTH-1:0] mem_minus_one;
    wire ecc_mismatch;
    
    // 预计算ECC并优化逻辑深度
    assign current_ecc = ^{data_in, 8'h00};
    assign stored_ecc = ^{mem[DATA_WIDTH-1:0], 8'h00};
    
    // 优化加减法逻辑路径
    assign mem_plus_one = mem + 1'b1;
    assign mem_minus_one = ~mem_plus_one + 1'b1;
    
    // 提前计算ECC错误检测
    assign ecc_mismatch = (stored_ecc != mem_minus_one[DATA_WIDTH+ECC_WIDTH-1:DATA_WIDTH]);
    
    always @(posedge clk) begin
        if (rst_sync) begin
            mem <= {(DATA_WIDTH+ECC_WIDTH){1'b0}};
            ecc_error <= 1'b0;
        end else if (ctx_write) begin
            mem <= {current_ecc, data_in};
        end else begin
            ecc_error <= ecc_mismatch;
        end
    end
    
    assign data_out = mem[DATA_WIDTH-1:0];

endmodule