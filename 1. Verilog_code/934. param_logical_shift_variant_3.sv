//SystemVerilog
module param_logical_shift #(
    parameter WIDTH = 16,
    parameter SHIFT_W = $clog2(WIDTH)
)(
    input wire signed [WIDTH-1:0] din,
    input wire [SHIFT_W-1:0] shift,
    input wire clk,
    input wire rst_n,
    output reg signed [WIDTH-1:0] dout
);

    // 中间流水线寄存器
    reg signed [WIDTH-1:0] din_reg;
    reg [SHIFT_W-1:0] shift_reg;
    reg signed [WIDTH-1:0] shift_stage1;
    
    // 将移位操作分解为多个阶段以减少逻辑深度
    wire signed [WIDTH-1:0] shift_result;
    
    // 流水线第一级：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= {WIDTH{1'b0}};
            shift_reg <= {SHIFT_W{1'b0}};
        end else begin
            din_reg <= din;
            shift_reg <= shift;
        end
    end
    
    // 流水线第二级：执行移位运算
    // 分解移位逻辑，降低组合逻辑复杂度
    assign shift_result = din_reg <<< shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_stage1 <= {WIDTH{1'b0}};
        end else begin
            shift_stage1 <= shift_result;
        end
    end
    
    // 流水线第三级：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
        end else begin
            dout <= shift_stage1;
        end
    end

endmodule