//SystemVerilog
module blowfish_pgen (
    input clk, 
    input rst_n,
    input init,
    input valid_in,
    input [31:0] key_segment,
    output reg valid_out,
    output reg [31:0] p_box_out
);
    // P-box storage
    reg [31:0] p_box [0:17];
    
    // Pipeline stage registers - 增加流水线深度
    reg [31:0] p_temp_stage1 [0:17];
    reg [31:0] p_temp_stage2 [0:17];
    reg [31:0] p_temp_stage3 [0:17];
    reg [31:0] p_temp_stage4 [0:17];
    
    reg [4:0] stage_counter;
    reg [4:0] next_stage_counter;
    
    // Pipeline control signals - 增加流水线控制信号
    reg pipeline_active;
    reg [4:0] pipeline_stage;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5, valid_stage6;
    
    // Processing states
    localparam IDLE = 2'b00;
    localparam INIT = 2'b01;
    localparam PROCESS = 2'b10;
    reg [1:0] state, next_state;
    
    // 计算中间值的寄存器
    reg [31:0] shift_temp1, shift_temp2;
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            stage_counter <= 5'd0;
            pipeline_active <= 1'b0;
            pipeline_stage <= 5'd0;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
            valid_stage5 <= 1'b0;
            valid_stage6 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            state <= next_state;
            stage_counter <= next_stage_counter;
            
            // 扩展的流水线有效性传播
            valid_stage1 <= valid_in && (state == PROCESS);
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
            valid_stage4 <= valid_stage3;
            valid_stage5 <= valid_stage4;
            valid_stage6 <= valid_stage5;
            valid_out <= valid_stage6;
            
            // Pipeline stage counter
            if (pipeline_active)
                pipeline_stage <= (pipeline_stage == 5'd17) ? 5'd0 : pipeline_stage + 5'd1;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        next_stage_counter = stage_counter;
        
        case (state)
            IDLE: begin
                if (init)
                    next_state = INIT;
                else if (valid_in)
                    next_state = PROCESS;
            end
            
            INIT: begin
                if (stage_counter == 5'd17) begin
                    next_state = IDLE;
                    next_stage_counter = 5'd0;
                end else
                    next_stage_counter = stage_counter + 5'd1;
            end
            
            PROCESS: begin
                if (!valid_in && pipeline_stage == 5'd17)
                    next_state = IDLE;
            end
        endcase
    end
    
    // P-box initialization and processing pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipeline_active <= 1'b0;
            p_box_out <= 32'd0;
            
            // 重置所有中间寄存器
            shift_temp1 <= 32'd0;
            shift_temp2 <= 32'd0;
        end else begin
            case (state)
                INIT: begin
                    // Initialize P-box with constants
                    p_box[stage_counter] <= 32'hB7E15163 + stage_counter * 32'h9E3779B9;
                end
                
                PROCESS: begin
                    pipeline_active <= 1'b1;
                    
                    // 流水线阶段1: 初始XOR和处理准备
                    if (pipeline_stage == 5'd0) begin
                        p_temp_stage1[0] <= p_box[0] ^ key_segment;
                    end
                    
                    // 流水线阶段2: 计算移位中间结果1 (元素0-5)
                    if (pipeline_stage > 5'd0 && pipeline_stage <= 5'd5) begin
                        shift_temp1 <= p_temp_stage1[pipeline_stage-1] << 1;
                        p_temp_stage1[pipeline_stage] <= p_box[pipeline_stage];
                    end
                    
                    // 流水线阶段3: 计算移位中间结果2并应用到元素1-5 
                    if (pipeline_stage > 5'd1 && pipeline_stage <= 5'd5) begin
                        shift_temp2 <= shift_temp1 << 2; // 相当于原来的<<3
                        p_temp_stage2[pipeline_stage-1] <= p_temp_stage1[pipeline_stage-1] + shift_temp1;
                    end
                    
                    // 流水线阶段4: 完成元素1-5的处理并开始处理6-11
                    if (pipeline_stage > 5'd2 && pipeline_stage <= 5'd5) begin
                        p_temp_stage3[pipeline_stage-2] <= p_temp_stage2[pipeline_stage-2] + shift_temp2;
                    end
                    
                    if (pipeline_stage > 5'd5 && pipeline_stage <= 5'd11) begin
                        shift_temp1 <= p_temp_stage3[pipeline_stage-6] << 1;
                        p_temp_stage1[pipeline_stage] <= p_box[pipeline_stage];
                    end
                    
                    // 流水线阶段5: 计算移位中间结果2并应用到元素6-11
                    if (pipeline_stage > 5'd6 && pipeline_stage <= 5'd11) begin
                        shift_temp2 <= shift_temp1 << 2;
                        p_temp_stage2[pipeline_stage-1] <= p_temp_stage1[pipeline_stage-1] + shift_temp1;
                    end
                    
                    // 流水线阶段6: 完成元素6-11的处理并开始处理12-17
                    if (pipeline_stage > 5'd7 && pipeline_stage <= 5'd11) begin
                        p_temp_stage3[pipeline_stage-2] <= p_temp_stage2[pipeline_stage-2] + shift_temp2;
                    end
                    
                    if (pipeline_stage > 5'd11 && pipeline_stage <= 5'd17) begin
                        shift_temp1 <= p_temp_stage3[pipeline_stage-12] << 1;
                        p_temp_stage1[pipeline_stage] <= p_box[pipeline_stage];
                    end
                    
                    // 流水线阶段7: 计算移位中间结果2并应用到元素12-17
                    if (pipeline_stage > 5'd12 && pipeline_stage <= 5'd17) begin
                        shift_temp2 <= shift_temp1 << 2;
                        p_temp_stage2[pipeline_stage-1] <= p_temp_stage1[pipeline_stage-1] + shift_temp1;
                    end
                    
                    // 流水线阶段8: 完成元素12-17的处理
                    if (pipeline_stage > 5'd13 && pipeline_stage <= 5'd17) begin
                        p_temp_stage3[pipeline_stage-2] <= p_temp_stage2[pipeline_stage-2] + shift_temp2;
                        
                        // 在最后一个元素处理完成时，更新p_box并输出
                        if (pipeline_stage == 5'd17) begin
                            p_temp_stage4[16] <= p_temp_stage3[15];
                            p_temp_stage4[17] <= p_temp_stage3[16];
                            
                            // 更新所有p_box值
                            p_box[0] <= p_temp_stage3[0];
                            p_box[1] <= p_temp_stage3[1];
                            p_box[2] <= p_temp_stage3[2];
                            p_box[3] <= p_temp_stage3[3];
                            p_box[4] <= p_temp_stage3[4];
                            p_box[5] <= p_temp_stage3[5];
                            p_box[6] <= p_temp_stage3[6];
                            p_box[7] <= p_temp_stage3[7];
                            p_box[8] <= p_temp_stage3[8];
                            p_box[9] <= p_temp_stage3[9];
                            p_box[10] <= p_temp_stage3[10];
                            p_box[11] <= p_temp_stage3[11];
                            p_box[12] <= p_temp_stage3[12];
                            p_box[13] <= p_temp_stage3[13];
                            p_box[14] <= p_temp_stage3[14];
                            p_box[15] <= p_temp_stage3[15];
                            p_box[16] <= p_temp_stage4[16];
                            p_box[17] <= p_temp_stage4[17];
                            
                            // 输出最后一个值
                            p_box_out <= p_temp_stage4[17];
                        end
                    end
                end
            endcase
        end
    end
endmodule