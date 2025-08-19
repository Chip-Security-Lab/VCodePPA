//SystemVerilog
module edge_sensitive_clock_gate (
    input  wire clk_in,
    input  wire data_valid,
    input  wire rst_n,
    output wire clk_out
);
    reg data_valid_r1, data_valid_r2;
    wire edge_detected;
    
    // 两级寄存器以减少亚稳态风险 - 使用条件运算符替代if-else
    always @(posedge clk_in or negedge rst_n) begin
        data_valid_r1 <= !rst_n ? 1'b0 : data_valid;
        data_valid_r2 <= !rst_n ? 1'b0 : data_valid_r1;
    end
    
    // 优化的边沿检测逻辑 - 使用XOR可以减少逻辑层级
    assign edge_detected = data_valid_r1 ^ data_valid_r2;
    
    // 使用AND门进行时钟门控
    assign clk_out = clk_in & (edge_detected & data_valid_r1);
endmodule