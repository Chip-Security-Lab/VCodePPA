//SystemVerilog
//IEEE 1364-2005
module pulse_clkgen #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst,
    output reg pulse
);
    // 流水线寄存器定义
    reg [WIDTH-1:0] delay_cnt;
    reg [WIDTH-1:0] delay_cnt_stage1;
    reg [WIDTH-1:0] delay_cnt_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 第一级流水线：生成基本的传播和生成信号
    wire [WIDTH-1:0] p_stage1, g_stage1;
    
    generate
        genvar i;
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p_stage1[i] = delay_cnt[i] | 1'b1; // P = a + b，这里b=1
            assign g_stage1[i] = delay_cnt[i] & 1'b1; // G = a · b，这里b=1
        end
    endgenerate
    
    // 第一级流水线寄存器
    reg [WIDTH-1:0] p_reg1, g_reg1;
    
    // 第二级流水线：组合逻辑
    wire [WIDTH-1:0] pp_stage2, gg_stage2;
    
    generate
        for (i = 0; i < WIDTH-1; i = i + 2) begin: gen_level1
            assign pp_stage2[i] = p_reg1[i] & p_reg1[i+1];
            assign gg_stage2[i] = g_reg1[i] | (p_reg1[i] & g_reg1[i+1]);
        end
    endgenerate
    
    // 第二级流水线寄存器
    reg [WIDTH-1:0] pp_reg2, gg_reg2;
    
    // 第三级流水线：生成最终进位和计算
    wire [WIDTH:0] carry_stage3;
    wire [WIDTH-1:0] next_delay_cnt_stage3;
    
    assign carry_stage3[0] = 1'b0; // 初始进位为0
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            if (i % 2 == 0 && i < WIDTH-1)
                assign carry_stage3[i+2] = gg_reg2[i] | (pp_reg2[i] & carry_stage3[i]);
            else if (i % 2 == 1)
                assign carry_stage3[i+1] = g_reg1[i] | (p_reg1[i] & carry_stage3[i]);
        end
    endgenerate
    
    // 计算最终加法结果
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign next_delay_cnt_stage3[i] = delay_cnt_stage2[i] ^ carry_stage3[i]; // 异或计算和
        end
    endgenerate
    
    // 流水线判决逻辑
    wire pulse_condition_stage3;
    assign pulse_condition_stage3 = (delay_cnt_stage2 == {WIDTH{1'b1}}) ? 1'b1 : 1'b0;
    
    // 流水线寄存器更新
    always @(posedge clk) begin
        if (rst) begin
            // 重置所有流水线寄存器
            delay_cnt <= {WIDTH{1'b0}};
            delay_cnt_stage1 <= {WIDTH{1'b0}};
            delay_cnt_stage2 <= {WIDTH{1'b0}};
            p_reg1 <= {WIDTH{1'b0}};
            g_reg1 <= {WIDTH{1'b0}};
            pp_reg2 <= {WIDTH{1'b0}};
            gg_reg2 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            pulse <= 1'b0;
        end else begin
            // 第一级流水线寄存器更新
            p_reg1 <= p_stage1;
            g_reg1 <= g_stage1;
            delay_cnt_stage1 <= delay_cnt;
            valid_stage1 <= 1'b1;
            
            // 第二级流水线寄存器更新
            pp_reg2 <= pp_stage2;
            gg_reg2 <= gg_stage2;
            delay_cnt_stage2 <= delay_cnt_stage1;
            valid_stage2 <= valid_stage1;
            
            // 第三级流水线：最终结果和输出
            if (valid_stage2) begin
                delay_cnt <= next_delay_cnt_stage3;
                valid_stage3 <= valid_stage2;
                pulse <= pulse_condition_stage3 & valid_stage2;
            end
        end
    end
endmodule