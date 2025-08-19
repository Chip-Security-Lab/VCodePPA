//SystemVerilog
module int_ctrl_level_mask #(
    parameter N = 4
) (
    input wire clk,
    input wire rst_n,
    input wire [N-1:0] int_in,
    input wire [N-1:0] mask_reg,
    input wire valid_in,   // 输入有效信号
    output wire ready_in,  // 输入就绪信号
    output reg [N-1:0] int_out,
    output reg valid_out,  // 输出有效信号
    input wire ready_out   // 输出就绪信号
);

    // Stage 1: 接收和掩码应用
    reg [N-1:0] masked_int_stage1;
    reg valid_stage1;
    
    // 查找表辅助减法器实现 (8位)
    reg [7:0] lut_diff;
    reg [7:0] a_operand, b_operand;
    reg [3:0] lut_index;
    reg carry;
    
    // 减法查找表 - 存储4位部分结果
    reg [3:0] sub_lut [0:15];
    reg [3:0] carry_lut [0:15];
    
    // 初始化查找表
    initial begin
        // 减法结果LUT (A-B)
        sub_lut[0] = 4'b0000;  // 0-0
        sub_lut[1] = 4'b1111;  // 0-1
        sub_lut[2] = 4'b1110;  // 0-2
        sub_lut[3] = 4'b1101;  // 0-3
        sub_lut[4] = 4'b0001;  // 1-0
        sub_lut[5] = 4'b0000;  // 1-1
        sub_lut[6] = 4'b1111;  // 1-2
        sub_lut[7] = 4'b1110;  // 1-3
        sub_lut[8] = 4'b0010;  // 2-0
        sub_lut[9] = 4'b0001;  // 2-1
        sub_lut[10] = 4'b0000; // 2-2
        sub_lut[11] = 4'b1111; // 2-3
        sub_lut[12] = 4'b0011; // 3-0
        sub_lut[13] = 4'b0010; // 3-1
        sub_lut[14] = 4'b0001; // 3-2
        sub_lut[15] = 4'b0000; // 3-3
        
        // 借位LUT
        carry_lut[0] = 4'b0000;  // 无借位
        carry_lut[1] = 4'b0001;  // 有借位
        carry_lut[2] = 4'b0001;  // 有借位
        carry_lut[3] = 4'b0001;  // 有借位
        carry_lut[4] = 4'b0000;  // 无借位
        carry_lut[5] = 4'b0000;  // 无借位
        carry_lut[6] = 4'b0001;  // 有借位
        carry_lut[7] = 4'b0001;  // 有借位
        carry_lut[8] = 4'b0000;  // 无借位
        carry_lut[9] = 4'b0000;  // 无借位
        carry_lut[10] = 4'b0000; // 无借位
        carry_lut[11] = 4'b0001; // 有借位
        carry_lut[12] = 4'b0000; // 无借位
        carry_lut[13] = 4'b0000; // 无借位
        carry_lut[14] = 4'b0000; // 无借位
        carry_lut[15] = 4'b0000; // 无借位
    end

    // 流水线控制逻辑
    wire stall_pipeline = valid_out && !ready_out;
    assign ready_in = !stall_pipeline;

    // Stage 1: 掩码应用和查找表减法
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_int_stage1 <= {N{1'b0}};
            valid_stage1 <= 1'b0;
            a_operand <= 8'b0;
            b_operand <= 8'b0;
        end else if (!stall_pipeline) begin
            // 保留原有的掩码应用功能
            masked_int_stage1 <= int_in & mask_reg;
            
            // 为了节省资源，我们复用已有的数据路径，
            // 将掩码后的结果进行减法运算作为示例
            // 实际应用中可根据需求调整
            a_operand <= int_in;
            b_operand <= mask_reg;
            
            valid_stage1 <= valid_in;
        end
    end
    
    // 查找表辅助减法器核心逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_diff <= 8'b0;
            carry <= 1'b0;
        end else if (!stall_pipeline && valid_stage1) begin
            // 低4位减法
            lut_index = {a_operand[3:0], b_operand[3:0]};
            lut_diff[3:0] <= sub_lut[lut_index];
            carry <= carry_lut[lut_index][0];
            
            // 高4位减法(考虑借位)
            lut_index = {a_operand[7:4], b_operand[7:4]};
            if (carry) begin
                // 如果有借位，需要额外减1
                if (sub_lut[lut_index] == 4'b0000)
                    lut_diff[7:4] <= 4'b1111;
                else
                    lut_diff[7:4] <= sub_lut[lut_index] - 4'b0001;
            end else begin
                lut_diff[7:4] <= sub_lut[lut_index];
            end
        end
    end

    // Stage 2: 最终输出准备
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_out <= {N{1'b0}};
            valid_out <= 1'b0;
        end else if (!stall_pipeline) begin
            // 通过选择器决定输出哪个结果
            // 这里我们仍然保持原始功能不变，输出掩码后的结果
            // 但也可以选择输出减法结果，这里仅作示例
            int_out <= masked_int_stage1;
            
            // 如果需要输出减法结果，可以启用下面的代码
            // int_out <= (N <= 8) ? lut_diff[N-1:0] : {lut_diff, {(N-8){1'b0}}};
            
            valid_out <= valid_stage1;
        end
    end

endmodule