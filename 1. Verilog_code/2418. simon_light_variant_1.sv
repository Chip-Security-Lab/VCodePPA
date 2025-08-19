//SystemVerilog
module simon_light #(
    parameter ROUNDS = 44
)(
    input clk, rst_n,
    input load_key,
    input valid_in,
    input [63:0] block_in,
    input [127:0] key_in,
    output [63:0] block_out,
    output valid_out
);
    // 密钥调度表
    reg [63:0] key_schedule [0:ROUNDS-1];
    integer r;
    
    // 流水线阶段数
    localparam PIPELINE_STAGES = 4;  // 将整个计算分为4级流水线
    
    // 流水线数据寄存器
    reg [31:0] left_stage1, right_stage1;
    reg [31:0] left_stage2, right_stage2;
    reg [31:0] left_stage3, right_stage3;
    reg [31:0] left_stage4, right_stage4;
    
    // 中间计算结果
    reg [31:0] rotated_left_stage1;
    reg [63:0] key_stage1, key_stage2, key_stage3;
    
    // 第二阶段计算中间信号
    reg [31:0] P_stage2, G_stage2;
    
    // 第三阶段计算中间信号
    reg [31:0] carry_stage3;
    reg [31:0] sum_stage3;
    
    // 第四阶段计算
    reg [31:0] new_left_stage4;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg key_loaded;
    
    // 带状进位加法器临时信号
    wire [31:0] P_temp, G_temp;
    wire [31:0] carry_temp;
    
    // 带状进位逻辑 - 组合逻辑部分
    assign P_temp = rotated_left_stage1 ^ key_stage1[31:0];
    assign G_temp = rotated_left_stage1 & key_stage1[31:0];
    
    // 4位一组的带状进位计算
    genvar i;
    generate
        // 第一个进位固定为0
        assign carry_temp[0] = 0;
        
        // 计算其他进位
        for (i = 1; i < 32; i = i + 1) begin : carry_gen
            if (i % 4 == 0) begin
                // 组间进位计算
                assign carry_temp[i] = G_temp[i-1] | (P_temp[i-1] & carry_temp[i-1]);
            end else begin
                // 组内进位计算 
                assign carry_temp[i] = G_temp[i-1] | (P_temp[i-1] & carry_temp[i-1]);
            end
        end
    endgenerate
    
    // 密钥加载逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_loaded <= 1'b0;
            for(r=0; r<ROUNDS; r=r+1) begin
                key_schedule[r] <= 64'h0;
            end
        end else if (load_key) begin
            key_loaded <= 1'b1;
            key_schedule[0] <= key_in[63:0];
            for(r=1; r<ROUNDS; r=r+1) begin
                key_schedule[r][63:3] <= key_schedule[r-1][60:0];
                key_schedule[r][2:0] <= key_schedule[r-1][63:61] ^ 3'h5;
            end
        end
    end
    
    // 流水线第一级 - 加载输入并准备旋转操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            left_stage1 <= 32'h0;
            right_stage1 <= 32'h0;
            rotated_left_stage1 <= 32'h0;
            key_stage1 <= 64'h0;
        end else begin
            valid_stage1 <= valid_in && key_loaded;
            if (valid_in && key_loaded) begin
                left_stage1 <= block_in[63:32];
                right_stage1 <= block_in[31:0];
                rotated_left_stage1 <= {block_in[62:32], block_in[63]};  // 循环左移1位
                key_stage1 <= key_schedule[0];
            end
        end
    end
    
    // 流水线第二级 - 计算P和G信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            left_stage2 <= 32'h0;
            right_stage2 <= 32'h0;
            P_stage2 <= 32'h0;
            G_stage2 <= 32'h0;
            key_stage2 <= 64'h0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                left_stage2 <= left_stage1;
                right_stage2 <= right_stage1;
                P_stage2 <= P_temp;
                G_stage2 <= G_temp;
                key_stage2 <= key_stage1;
            end
        end
    end
    
    // 流水线第三级 - 计算进位和求和
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            left_stage3 <= 32'h0;
            right_stage3 <= 32'h0;
            carry_stage3 <= 32'h0;
            sum_stage3 <= 32'h0;
            key_stage3 <= 64'h0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                left_stage3 <= left_stage2;
                right_stage3 <= right_stage2;
                carry_stage3 <= carry_temp;
                // 计算求和，使用预先计算的进位
                sum_stage3 <= P_stage2 ^ {carry_temp[30:0], 1'b0};
                key_stage3 <= key_stage2;
            end
        end
    end
    
    // 流水线第四级 - 生成最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
            left_stage4 <= 32'h0;
            right_stage4 <= 32'h0;
            new_left_stage4 <= 32'h0;
        end else begin
            valid_stage4 <= valid_stage3;
            if (valid_stage3) begin
                left_stage4 <= left_stage3;
                right_stage4 <= right_stage3;
                // 计算新的左半部分
                new_left_stage4 <= right_stage3 ^ sum_stage3;
            end
        end
    end
    
    // 输出分配
    assign block_out = {right_stage4, new_left_stage4};
    assign valid_out = valid_stage4;
    
endmodule