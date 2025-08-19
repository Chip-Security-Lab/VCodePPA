//SystemVerilog
module and_or_xor_operator (
    input wire clk,                     // 时钟信号
    input wire rst_n,                   // 复位信号
    input wire [7:0] a,                 // 输入操作数A
    input wire [7:0] b,                 // 输入操作数B
    output reg [7:0] and_result,        // 与操作结果
    output reg [7:0] or_result,         // 或操作结果
    output reg [7:0] xor_result         // 异或操作结果
);

    // 中间寄存器，用于分割数据路径
    reg [7:0] a_reg, b_reg;              // 输入寄存器级
    reg [7:0] and_op_stage1;             // 与操作第一级
    reg [7:0] or_op_stage1;              // 或操作第一级
    reg [7:0] xor_op_stage1;             // 异或操作第一级
    
    // 分段计算组合逻辑
    wire [3:0] and_low, and_high;
    wire [3:0] or_low, or_high;
    wire [3:0] xor_low, xor_high;
    
    // 第一级流水线 - 寄存输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h00;
            b_reg <= 8'h00;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // 分离低位和高位操作以减少逻辑深度
    assign and_low = a_reg[3:0] & b_reg[3:0];
    assign and_high = a_reg[7:4] & b_reg[7:4];
    
    assign or_low = a_reg[3:0] | b_reg[3:0];
    assign or_high = a_reg[7:4] | b_reg[7:4];
    
    assign xor_low = a_reg[3:0] ^ b_reg[3:0];
    assign xor_high = a_reg[7:4] ^ b_reg[7:4];
    
    // 第二级流水线 - 计算各种操作结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_op_stage1 <= 8'h00;
            or_op_stage1 <= 8'h00;
            xor_op_stage1 <= 8'h00;
        end else begin
            and_op_stage1 <= {and_high, and_low};
            or_op_stage1 <= {or_high, or_low};
            xor_op_stage1 <= {xor_high, xor_low};
        end
    end
    
    // 第三级流水线 - 输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 8'h00;
            or_result <= 8'h00;
            xor_result <= 8'h00;
        end else begin
            and_result <= and_op_stage1;
            or_result <= or_op_stage1;
            xor_result <= xor_op_stage1;
        end
    end

endmodule