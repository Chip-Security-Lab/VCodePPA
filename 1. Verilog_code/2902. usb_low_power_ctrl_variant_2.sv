//SystemVerilog
module usb_low_power_ctrl(
    input clk_48mhz,
    input reset_n,
    input bus_activity,
    input suspend_req,
    input resume_req,
    output reg suspend_state,
    output reg clk_en,
    output reg pll_en
);
    // Pipeline stages
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    
    // Stage 1: State determination and counter management
    reg [1:0] state_stage1, state_stage2;
    reg [15:0] idle_counter_stage1, idle_counter_stage2;
    reg bus_activity_stage1, suspend_req_stage1, resume_req_stage1;
    reg active_to_idle_stage1, idle_to_active_stage1, idle_to_suspend_stage1;
    reg suspend_to_resume_stage1, resume_complete_stage1;
    reg [15:0] next_counter_stage1;
    reg counter_reset_stage1;
    
    // Stage 2: Output generation
    reg suspend_state_next_stage2;
    reg clk_en_next_stage2;
    reg pll_en_next_stage2;
    
    // 跳跃进位加法器的内部信号
    // 分为4个4位的块
    wire [15:0] sum;
    wire [3:0] block_prop; // 块传播信号
    wire [4:0] carry; // 进位信号，包括初始进位和每个块的输出进位
    wire [15:0] p, g; // 局部传播和生成信号
    
    // 计算局部传播和生成信号
    assign p = idle_counter_stage1;
    assign g = 16'd0; // 在加1操作中，生成信号为0
    
    // 初始进位为1（因为是加1操作）
    assign carry[0] = 1'b1;
    
    // 第一个4位块的进位链
    wire [3:0] c_block0;
    assign c_block0[0] = carry[0];
    assign c_block0[1] = g[0] | (p[0] & c_block0[0]);
    assign c_block0[2] = g[1] | (p[1] & c_block0[1]);
    assign c_block0[3] = g[2] | (p[2] & c_block0[2]);
    assign carry[1] = g[3] | (p[3] & c_block0[3]);
    
    // 计算第一个块是否传播进位
    assign block_prop[0] = p[0] & p[1] & p[2] & p[3];
    
    // 第二个4位块的进位链
    wire [3:0] c_block1;
    wire c_skip1;
    assign c_skip1 = block_prop[0] ? carry[0] : carry[1];
    assign c_block1[0] = c_skip1;
    assign c_block1[1] = g[4] | (p[4] & c_block1[0]);
    assign c_block1[2] = g[5] | (p[5] & c_block1[1]);
    assign c_block1[3] = g[6] | (p[6] & c_block1[2]);
    assign carry[2] = g[7] | (p[7] & c_block1[3]);
    
    // 计算第二个块是否传播进位
    assign block_prop[1] = p[4] & p[5] & p[6] & p[7];
    
    // 第三个4位块的进位链
    wire [3:0] c_block2;
    wire c_skip2;
    assign c_skip2 = block_prop[1] ? c_skip1 : carry[2];
    assign c_block2[0] = c_skip2;
    assign c_block2[1] = g[8] | (p[8] & c_block2[0]);
    assign c_block2[2] = g[9] | (p[9] & c_block2[1]);
    assign c_block2[3] = g[10] | (p[10] & c_block2[2]);
    assign carry[3] = g[11] | (p[11] & c_block2[3]);
    
    // 计算第三个块是否传播进位
    assign block_prop[2] = p[8] & p[9] & p[10] & p[11];
    
    // 第四个4位块的进位链
    wire [3:0] c_block3;
    wire c_skip3;
    assign c_skip3 = block_prop[2] ? c_skip2 : carry[3];
    assign c_block3[0] = c_skip3;
    assign c_block3[1] = g[12] | (p[12] & c_block3[0]);
    assign c_block3[2] = g[13] | (p[13] & c_block3[1]);
    assign c_block3[3] = g[14] | (p[14] & c_block3[2]);
    assign carry[4] = g[15] | (p[15] & c_block3[3]);
    
    // 计算第四个块是否传播进位
    assign block_prop[3] = p[12] & p[13] & p[14] & p[15];
    
    // 计算和
    assign sum[0] = p[0] ^ carry[0];
    assign sum[1] = p[1] ^ c_block0[1];
    assign sum[2] = p[2] ^ c_block0[2];
    assign sum[3] = p[3] ^ c_block0[3];
    
    assign sum[4] = p[4] ^ c_block1[0];
    assign sum[5] = p[5] ^ c_block1[1];
    assign sum[6] = p[6] ^ c_block1[2];
    assign sum[7] = p[7] ^ c_block1[3];
    
    assign sum[8] = p[8] ^ c_block2[0];
    assign sum[9] = p[9] ^ c_block2[1];
    assign sum[10] = p[10] ^ c_block2[2];
    assign sum[11] = p[11] ^ c_block2[3];
    
    assign sum[12] = p[12] ^ c_block3[0];
    assign sum[13] = p[13] ^ c_block3[1];
    assign sum[14] = p[14] ^ c_block3[2];
    assign sum[15] = p[15] ^ c_block3[3];
    
    // Stage 1: Input registration and state determination
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            // Reset stage 1 registers
            state_stage1 <= ACTIVE;
            idle_counter_stage1 <= 16'd0;
            bus_activity_stage1 <= 1'b0;
            suspend_req_stage1 <= 1'b0;
            resume_req_stage1 <= 1'b0;
            
            // Reset transition signals
            active_to_idle_stage1 <= 1'b0;
            idle_to_active_stage1 <= 1'b0;
            idle_to_suspend_stage1 <= 1'b0;
            suspend_to_resume_stage1 <= 1'b0;
            resume_complete_stage1 <= 1'b0;
            
            next_counter_stage1 <= 16'd0;
            counter_reset_stage1 <= 1'b0;
        end else begin
            // Register inputs
            bus_activity_stage1 <= bus_activity;
            suspend_req_stage1 <= suspend_req;
            resume_req_stage1 <= resume_req;
            
            // Default values for control signals
            active_to_idle_stage1 <= 1'b0;
            idle_to_active_stage1 <= 1'b0;
            idle_to_suspend_stage1 <= 1'b0;
            suspend_to_resume_stage1 <= 1'b0;
            resume_complete_stage1 <= 1'b0;
            counter_reset_stage1 <= 1'b0;
            
            // Counter logic - 使用跳跃进位加法器
            if (bus_activity_stage1 && (state_stage1 == ACTIVE || state_stage1 == IDLE)) begin
                next_counter_stage1 <= 16'd0;
                counter_reset_stage1 <= 1'b1;
            end else if (state_stage1 != SUSPEND) begin
                next_counter_stage1 <= sum;  // 使用跳跃进位加法器的结果
            end
            
            // State transition logic
            case (state_stage1)
                ACTIVE: begin
                    if (!bus_activity_stage1 && (idle_counter_stage1 > 16'd3000 || suspend_req_stage1)) begin
                        active_to_idle_stage1 <= 1'b1;
                    end
                end
                
                IDLE: begin
                    if (bus_activity_stage1) begin
                        idle_to_active_stage1 <= 1'b1;
                    end else if (idle_counter_stage1 > 16'd20000) begin
                        idle_to_suspend_stage1 <= 1'b1;
                    end
                end
                
                SUSPEND: begin
                    if (bus_activity_stage1 || resume_req_stage1) begin
                        suspend_to_resume_stage1 <= 1'b1;
                        next_counter_stage1 <= 16'd0;
                    end
                end
                
                RESUME: begin
                    if (idle_counter_stage1 >= 16'd1000) begin
                        resume_complete_stage1 <= 1'b1;
                    end
                end
            endcase
            
            // Update counter
            if (!counter_reset_stage1) begin
                idle_counter_stage1 <= next_counter_stage1;
            end else begin
                idle_counter_stage1 <= 16'd0;
            end
        end
    end
    
    // Pipeline register between stage 1 and stage 2
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            state_stage2 <= ACTIVE;
            idle_counter_stage2 <= 16'd0;
        end else begin
            // Transfer state and transition signals to stage 2
            if (active_to_idle_stage1)
                state_stage2 <= IDLE;
            else if (idle_to_active_stage1)
                state_stage2 <= ACTIVE;
            else if (idle_to_suspend_stage1)
                state_stage2 <= SUSPEND;
            else if (suspend_to_resume_stage1)
                state_stage2 <= RESUME;
            else if (resume_complete_stage1)
                state_stage2 <= ACTIVE;
            else
                state_stage2 <= state_stage1;
                
            idle_counter_stage2 <= idle_counter_stage1;
        end
    end
    
    // Stage 2: Output generation based on state
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            suspend_state <= 1'b0;
            clk_en <= 1'b1;
            pll_en <= 1'b1;
            
            suspend_state_next_stage2 <= 1'b0;
            clk_en_next_stage2 <= 1'b1;
            pll_en_next_stage2 <= 1'b1;
        end else begin
            // Determine outputs based on current state
            case (state_stage2)
                ACTIVE: begin
                    suspend_state_next_stage2 <= 1'b0;
                    clk_en_next_stage2 <= 1'b1;
                    pll_en_next_stage2 <= 1'b1;
                end
                
                IDLE: begin
                    suspend_state_next_stage2 <= suspend_state;
                    clk_en_next_stage2 <= clk_en;
                    pll_en_next_stage2 <= pll_en;
                    
                    if (idle_to_suspend_stage1) begin
                        suspend_state_next_stage2 <= 1'b1;
                        clk_en_next_stage2 <= 1'b0;
                        pll_en_next_stage2 <= 1'b0;
                    end
                end
                
                SUSPEND: begin
                    suspend_state_next_stage2 <= 1'b1;
                    clk_en_next_stage2 <= 1'b0;
                    
                    if (suspend_to_resume_stage1) begin
                        pll_en_next_stage2 <= 1'b1;
                    end else begin
                        pll_en_next_stage2 <= 1'b0;
                    end
                end
                
                RESUME: begin
                    suspend_state_next_stage2 <= suspend_state;
                    pll_en_next_stage2 <= 1'b1;
                    
                    if (resume_complete_stage1) begin
                        suspend_state_next_stage2 <= 1'b0;
                        clk_en_next_stage2 <= 1'b1;
                    end else begin
                        clk_en_next_stage2 <= clk_en;
                    end
                end
            endcase
            
            // Register the outputs
            suspend_state <= suspend_state_next_stage2;
            clk_en <= clk_en_next_stage2;
            pll_en <= pll_en_next_stage2;
        end
    end
endmodule