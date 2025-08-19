//SystemVerilog
// 顶层模块
module counter_bcd (
    input clk,           // 时钟信号
    input rst,           // 复位信号
    input en,            // 使能信号
    output [3:0] bcd,    // BCD计数值输出
    output carry         // 进位输出
);
    // 内部信号定义
    wire next_carry;
    wire [3:0] next_bcd;
    
    // 子模块实例化
    bcd_logic_unit logic_unit (
        .clk(clk),
        .rst(rst),
        .current_bcd(bcd),
        .en(en),
        .next_bcd(next_bcd),
        .carry_out(next_carry)
    );
    
    bcd_register reg_unit (
        .clk(clk),
        .rst(rst),
        .next_bcd(next_bcd),
        .bcd_out(bcd)
    );
    
    carry_register carry_unit (
        .clk(clk),
        .rst(rst),
        .carry_in(next_carry),
        .carry_out(carry)
    );
    
endmodule

// BCD逻辑单元 - 负责计算下一个BCD值，采用流水线处理
module bcd_logic_unit (
    input clk,
    input rst,
    input [3:0] current_bcd,
    input en,
    output reg [3:0] next_bcd,
    output reg carry_out
);
    // 中间流水线寄存器
    reg comparison_result;
    reg [3:0] incremented_value;
    
    // 第一阶段：比较和加法操作
    always @(posedge clk) begin
        if (rst) begin
            comparison_result <= 1'b0;
            incremented_value <= 4'd0;
        end
        else begin
            comparison_result <= (current_bcd == 4'd9) & en;
            incremented_value <= current_bcd + 4'd1;
        end
    end
    
    // 第二阶段：最终输出计算
    always @(posedge clk) begin
        if (rst) begin
            next_bcd <= 4'd0;
            carry_out <= 1'b0;
        end
        else begin
            next_bcd <= comparison_result ? 4'd0 : incremented_value;
            carry_out <= comparison_result;
        end
    end
    
endmodule

// BCD寄存器单元 - 存储当前BCD值
module bcd_register (
    input clk,
    input rst,
    input [3:0] next_bcd,
    output reg [3:0] bcd_out
);
    always @(posedge clk) begin
        if (rst)
            bcd_out <= 4'd0;
        else
            bcd_out <= next_bcd;
    end
endmodule

// 进位寄存器单元 - 处理进位信号，增加寄存器同步
module carry_register (
    input clk,
    input rst,
    input carry_in,
    output reg carry_out
);
    always @(posedge clk) begin
        if (rst)
            carry_out <= 1'b0;
        else
            carry_out <= carry_in;
    end
endmodule