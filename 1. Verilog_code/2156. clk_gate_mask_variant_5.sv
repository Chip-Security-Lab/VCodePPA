//SystemVerilog
module clk_gate_mask #(
    parameter MASK = 4'b1100
)(
    input  wire       clk,
    input  wire       en,
    output wire [3:0] out
);
    // 内部连线
    wire [3:0] current_out;
    wire [3:0] next_out;
    
    // 实例化功能子模块
    mask_logic_unit #(
        .MASK(MASK)
    ) mask_logic (
        .current_value(current_out),
        .enable(en),
        .next_value(next_out)
    );
    
    output_register output_reg (
        .clk(clk),
        .next_value(next_out),
        .current_value(current_out)
    );
    
    // 连接输出
    assign out = current_out;
    
endmodule

// 掩码逻辑单元 - 处理掩码应用逻辑
module mask_logic_unit #(
    parameter MASK = 4'b1100
)(
    input  wire [3:0] current_value,
    input  wire       enable,
    output reg  [3:0] next_value
);
    // 使用if-else结构替代条件运算符
    always @(*) begin
        if (enable) begin
            next_value = current_value | MASK;
        end
        else begin
            next_value = current_value;
        end
    end
    
endmodule

// 输出寄存器 - 存储和同步输出值
module output_register (
    input  wire       clk,
    input  wire [3:0] next_value,
    output reg  [3:0] current_value
);
    // 在时钟上升沿更新输出值
    always @(posedge clk) begin
        current_value <= next_value;
    end
    
endmodule