//SystemVerilog
// IEEE 1364-2005 Verilog标准
module priority_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high_pri,
    input wire high_pri_valid,
    input wire [WIDTH-1:0] data_low_pri,
    input wire low_pri_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // 优化的选择逻辑 - 使用三元运算符替代always块
    wire [WIDTH-1:0] data_selected;
    wire update_valid;
    
    // 使用OR优化update_valid信号
    assign update_valid = high_pri_valid | low_pri_valid;
    
    // 使用三元运算符优化数据选择，减少RTL资源使用
    assign data_selected = high_pri_valid ? data_high_pri : data_low_pri;
    
    // 注册更新逻辑 - 合并复位和条件更新到同一逻辑路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_out <= {WIDTH{1'b0}};
        else if (update_valid)
            shadow_out <= data_selected;
        // 隐含else保持当前值
    end
endmodule