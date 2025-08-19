//SystemVerilog
module ParamHamming_Encoder #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH+4:0] code_out
);
    // 计算校验位数量，简化为固定值4
    parameter PARITY_BITS = 4;
    reg [DATA_WIDTH-1:0] data_reg;
    reg [PARITY_BITS-1:0] parity;
    integer i, j;
    
    // 中间变量，用于计算校验位
    reg [PARITY_BITS-1:0] parity_calc;
    reg [DATA_WIDTH-1:0] count_ones;
    
    // 校验位掩码信号
    wire [PARITY_BITS-1:0] parity_masks[DATA_WIDTH-1:0];
    
    // 生成校验位掩码
    genvar k, m;
    generate
        for(k=0; k<DATA_WIDTH; k=k+1) begin: mask_gen
            for(m=0; m<PARITY_BITS; m=m+1) begin: bit_mask
                assign parity_masks[k][m] = ((k+1) & (1 << m)) ? 1'b1 : 1'b0;
            end
        end
    endgenerate
    
    // 进位计算的中间信号
    wire [DATA_WIDTH-1:0] p_stage1, g_stage1;
    wire [DATA_WIDTH/2-1:0] p_stage2, g_stage2;
    wire [DATA_WIDTH/4-1:0] p_stage3, g_stage3;
    wire p_final, g_final;
    wire [DATA_WIDTH:0] carry;
    wire [DATA_WIDTH-1:0] sum;
    
    // 定义状态计数器，用于多级计算
    reg [2:0] compute_state;
    reg compute_done;
    
    // 第一级：计算p和g
    generate
        for(k=0; k<DATA_WIDTH; k=k+1) begin: pg_gen
            assign p_stage1[k] = count_ones[k];
            assign g_stage1[k] = 1'b0;
        end
    endgenerate
    
    // 第二级：每2个bit一组
    generate
        for(k=0; k<DATA_WIDTH/2; k=k+1) begin: prefix_l1
            assign p_stage2[k] = p_stage1[2*k] & p_stage1[2*k+1];
            assign g_stage2[k] = g_stage1[2*k] | (p_stage1[2*k] & g_stage1[2*k+1]);
        end
    endgenerate
    
    // 第三级：每4个bit一组
    generate
        for(k=0; k<DATA_WIDTH/4; k=k+1) begin: prefix_l2
            assign p_stage3[k] = p_stage2[2*k] & p_stage2[2*k+1];
            assign g_stage3[k] = g_stage2[2*k] | (p_stage2[2*k] & g_stage2[2*k+1]);
        end
    endgenerate
    
    // 最终级：完成8位前缀计算
    assign p_final = p_stage3[0] & p_stage3[1];
    assign g_final = g_stage3[0] | (p_stage3[0] & g_stage3[1]);
    
    // 进位计算
    assign carry[0] = 1'b0;
    assign carry[DATA_WIDTH] = g_final;
    assign carry[4] = g_stage3[0];
    assign carry[2] = g_stage2[0];
    assign carry[1] = g_stage1[0];
    
    // 分阶段计算中间进位
    assign carry[3] = g_stage2[1] | (p_stage2[1] & carry[2]);
    assign carry[5] = g_stage1[4] | (p_stage1[4] & carry[4]);
    assign carry[6] = g_stage2[2] | (p_stage2[2] & carry[4]);
    assign carry[7] = g_stage2[3] | (p_stage2[3] & carry[6]);
    
    // 计算和
    generate
        for(k=0; k<DATA_WIDTH; k=k+1) begin: sum_gen
            assign sum[k] = p_stage1[k] ^ carry[k];
        end
    endgenerate
    
    // 控制信号和中间变量的声明
    reg data_loaded;
    reg parity_computed;
    reg [DATA_WIDTH-1:0] bit_counter;
    
    always @(posedge clk) begin
        if (en) begin
            if (!data_loaded) begin
                // 第一阶段：加载数据并初始化变量
                data_reg <= data_in;
                count_ones <= 0;
                compute_state <= 3'b000;
                compute_done <= 1'b0;
                data_loaded <= 1'b1;
                parity_computed <= 1'b0;
                bit_counter <= 0;
            end
            else if (!compute_done) begin
                case (compute_state)
                    3'b000: begin
                        // 第二阶段：计算每个校验位覆盖的数据位中1的个数
                        if (bit_counter < DATA_WIDTH) begin
                            for (i = 0; i < PARITY_BITS; i = i + 1) begin
                                if (parity_masks[bit_counter][i]) begin
                                    count_ones[i] <= count_ones[i] + data_reg[bit_counter];
                                end
                            end
                            bit_counter <= bit_counter + 1;
                        end 
                        else begin
                            compute_state <= 3'b001;
                            bit_counter <= 0;
                        end
                    end
                    3'b001: begin
                        // 第三阶段：从计算结果中提取奇偶校验位
                        for (i = 0; i < PARITY_BITS; i = i + 1) begin
                            parity[i] <= sum[i] & 1'b1;
                        end
                        compute_state <= 3'b010;
                    end
                    3'b010: begin
                        // 第四阶段：组合输出 - 先放置校验位
                        code_out[DATA_WIDTH+4:DATA_WIDTH+1] <= data_reg;
                        code_out[0] <= parity[0];
                        code_out[1] <= parity[1];
                        code_out[3] <= parity[2];
                        code_out[7] <= parity[3];
                        compute_state <= 3'b011;
                    end
                    3'b011: begin
                        // 第五阶段：插入数据位
                        j = 0;
                        for (i = 0; i < DATA_WIDTH+5; i = i + 1) begin
                            // 使用独立的条件判断而不是复杂表达式
                            if (i == 0 || i == 1 || i == 3 || i == 7) begin
                                // 这些位置是校验位，已经在前一阶段设置
                            end 
                            else begin
                                if (j < DATA_WIDTH) begin
                                    code_out[i] <= data_reg[j];
                                    j = j + 1;
                                end
                            end
                        end
                        compute_done <= 1'b1;
                    end
                    default: begin
                        // 默认情况下不执行任何操作
                    end
                endcase
            end
            else begin
                // 计算完成，等待下一个周期或复位
                if (en) begin
                    // 重置为初始状态以接收新数据
                    data_loaded <= 1'b0;
                    compute_done <= 1'b0;
                end
            end
        end
        else begin
            // 当en无效时，重置状态机
            data_loaded <= 1'b0;
            compute_done <= 1'b0;
            compute_state <= 3'b000;
        end
    end
endmodule