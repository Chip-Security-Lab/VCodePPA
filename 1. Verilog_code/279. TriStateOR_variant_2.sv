//SystemVerilog
module TriStateOR(
    input        clk,      // 时钟信号
    input        rst_n,    // 复位信号
    input        oe,       // 输出使能
    input  [7:0] a,        // 输入数据a
    input  [7:0] b,        // 输入数据b
    output [7:0] y         // 输出数据
);
    // 分离数据流阶段，增加流水线结构
    reg [7:0] a_reg, b_reg;      // 注册输入数据
    reg       oe_reg;            // 注册输出使能
    reg [7:0] or_result;         // 保存OR操作结果
    reg [7:0] y_reg;             // 输出寄存器
    
    // 第一阶段：注册输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
            b_reg <= 8'h0;
            oe_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            oe_reg <= oe;
        end
    end
    
    // 第二阶段：执行OR操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result <= 8'h0;
        end else begin
            or_result <= a_reg | b_reg;
        end
    end
    
    // 第三阶段：应用三态输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_reg <= 8'hz;
        end else begin
            y_reg <= oe_reg ? or_result : 8'hzz;
        end
    end
    
    // 最终输出
    assign y = y_reg;
    
endmodule