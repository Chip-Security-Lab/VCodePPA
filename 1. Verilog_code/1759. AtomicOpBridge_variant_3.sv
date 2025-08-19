//SystemVerilog
module AtomicOpBridge #(
    parameter DATA_W = 32
)(
    input clk, rst_n,
    input [1:0] op_type, // 0:SUB,1:AND,2:OR,3:XOR
    input [DATA_W-1:0] operand,
    output reg [DATA_W-1:0] reg_data
);
    // 内部信号定义
    wire [DATA_W-1:0] sub_result;
    wire [DATA_W-1:0] and_result, or_result, xor_result;
    
    // 生成与、或、异或结果
    assign and_result = reg_data & operand;
    assign or_result = reg_data | operand;
    assign xor_result = reg_data ^ operand;
    
    // 2位并行前缀减法器实现
    wire [DATA_W-1:0] p, g; // 传播和生成信号
    wire [DATA_W-1:0] carry; // 进位信号
    
    // 计算传播和生成信号
    assign p = reg_data ^ (~operand);
    assign g = reg_data & (~operand);
    
    // 2位并行前缀树计算进位
    genvar i;
    generate
        for (i = 0; i < DATA_W; i = i + 2) begin: prefix_block
            if (i == 0) begin
                // 第一位进位为生成信号
                assign carry[i] = g[i];
                
                // 第二位进位 = g[i+1] | (p[i+1] & g[i])
                if (i+1 < DATA_W) begin
                    assign carry[i+1] = g[i+1] | (p[i+1] & g[i]);
                end
            end else begin
                // 跨2位区块的进位传播
                // 区块起始位进位 = g[i] | (p[i] & carry[i-1])
                assign carry[i] = g[i] | (p[i] & carry[i-1]);
                
                // 第二位进位 = g[i+1] | (p[i+1] & (g[i] | (p[i] & carry[i-1])))
                if (i+1 < DATA_W) begin
                    assign carry[i+1] = g[i+1] | (p[i+1] & carry[i]);
                end
            end
        end
    endgenerate
    
    // 计算最终减法结果
    assign sub_result[0] = p[0] ^ 1'b1; // 减法需要初始进位为1
    
    genvar j;
    generate
        for (j = 1; j < DATA_W; j = j + 1) begin: sum_gen
            assign sub_result[j] = p[j] ^ carry[j-1];
        end
    endgenerate
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            reg_data <= 0;
        else 
            case(op_type)
                2'b00: reg_data <= sub_result;  // 使用并行前缀减法器
                2'b01: reg_data <= and_result;
                2'b10: reg_data <= or_result;
                2'b11: reg_data <= xor_result;
                default: reg_data <= reg_data; // 默认情况
            endcase
    end
endmodule