//SystemVerilog
module binary_to_onehot_sync #(parameter ADDR_WIDTH = 4) (
    input                        clk,
    input                        rst_n,
    input                        enable,
    input      [ADDR_WIDTH-1:0]  binary_in,
    output reg [2**ADDR_WIDTH-1:0] onehot_out
);
    // 优化管线寄存器结构
    reg [ADDR_WIDTH-1:0] binary_in_reg;
    reg enable_reg;
    reg [2**ADDR_WIDTH-1:0] onehot_intermediate;
    
    // 优化第一级流水线：注册输入并添加使能条件以减少功耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_in_reg <= {ADDR_WIDTH{1'b0}};
            enable_reg <= 1'b0;
        end
        else if (enable) begin
            binary_in_reg <= binary_in;
            enable_reg <= enable;
        end
    end
    
    // 优化第二级流水线：使用条件分支优先级减少逻辑电路消耗
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_intermediate <= {(2**ADDR_WIDTH){1'b0}};
        else if (enable_reg) begin
            // 使用更高效的方式生成独热编码
            onehot_intermediate <= 1'b1 << binary_in_reg;
        end
        else begin
            // 保持当前值以减少切换次数
            onehot_intermediate <= onehot_intermediate;
        end
    end
    
    // 优化最后级流水线：仅在必要时更新输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            onehot_out <= {(2**ADDR_WIDTH){1'b0}};
        else if (enable_reg)
            onehot_out <= onehot_intermediate;
    end
endmodule