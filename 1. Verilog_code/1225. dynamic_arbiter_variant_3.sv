//SystemVerilog
module dynamic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] pri_map,  // External priority
    output reg [WIDTH-1:0] grant_o
);
    // Pre-compute masked requests
    wire [WIDTH-1:0] masked_req = req_i & pri_map;
    
    // Priority encoder implementation with optimized path
    wire [WIDTH-1:0] priority_vector;
    
    // 优化的优先级编码器，使用一种更高效的实现方式
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin : gen_priority
            // 使用位运算替代对高位的逐一检查以减少关键路径
            wire [WIDTH-1:0] mask = {WIDTH{1'b1}} << (j + 1);
            wire [WIDTH-1:0] higher_bits = masked_req & mask;
            
            assign priority_vector[j] = masked_req[j] & ~(|higher_bits);
        end
    endgenerate

    // 同步输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_o <= {WIDTH{1'b0}};
        end else begin
            grant_o <= priority_vector;
        end
    end
endmodule