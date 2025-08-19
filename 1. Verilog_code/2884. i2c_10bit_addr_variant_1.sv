//SystemVerilog
module i2c_10bit_addr #(
    parameter ADDR_MODE = 0  // 0-7bit, 1-10bit
)(
    input clk,
    input rst_sync,
    inout sda,
    inout scl,
    input [9:0] target_addr,
    output reg addr_valid
);
    // 混合地址模式支持
    reg [9:0] addr_shift_stage1, addr_shift_stage2, addr_shift_stage3;
    reg addr_phase_stage1, addr_phase_stage2, addr_phase_stage3;
    reg [7:0] shift_reg_stage1, shift_reg_stage2;
    
    // 定义状态
    localparam IDLE = 3'b000;
    localparam ADDR_PHASE1_DETECT = 3'b001;
    localparam ADDR_PHASE1_PROCESS = 3'b010;
    localparam ADDR_PHASE2_DETECT = 3'b011;
    localparam ADDR_PHASE2_PROCESS = 3'b100;
    localparam DATA_PHASE = 3'b101;
    
    reg [2:0] state, next_state;
    reg [2:0] bit_count_stage1, bit_count_stage2;
    reg reset_bit_count;
    
    // I2C信号寄存
    reg sda_reg1, sda_reg2;
    reg scl_reg1, scl_reg2;
    
    // SDA/SCL采样寄存
    always @(posedge clk) begin
        if (rst_sync) begin
            sda_reg1 <= 1'b1;
            sda_reg2 <= 1'b1;
            scl_reg1 <= 1'b1;
            scl_reg2 <= 1'b1;
        end else begin
            sda_reg1 <= sda;
            sda_reg2 <= sda_reg1;
            scl_reg1 <= scl;
            scl_reg2 <= scl_reg1;
        end
    end
    
    // 状态寄存器更新 - 第一级流水线
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 状态转换逻辑 - 第一级流水线，处理状态转换决策
    always @(*) begin
        next_state = state;
        reset_bit_count = 1'b0;
        
        case(state)
            IDLE: begin
                if (sda_reg2 == 1'b0 && scl_reg2 == 1'b1) begin
                    next_state = ADDR_PHASE1_DETECT;
                    reset_bit_count = 1'b1;
                end
            end
            
            ADDR_PHASE1_DETECT: begin
                if (bit_count_stage2 == 3'b000 && scl_reg2 == 1'b0) begin
                    next_state = ADDR_PHASE1_PROCESS;
                end
            end
            
            ADDR_PHASE1_PROCESS: begin
                if (ADDR_MODE == 0) begin
                    next_state = DATA_PHASE;
                end else begin
                    if (shift_reg_stage2[7:3] == 5'b11110) begin
                        next_state = ADDR_PHASE2_DETECT;
                    end else begin
                        next_state = IDLE;
                    end
                end
            end
            
            ADDR_PHASE2_DETECT: begin
                if (bit_count_stage2 == 3'b000 && scl_reg2 == 1'b0) begin
                    next_state = ADDR_PHASE2_PROCESS;
                end
            end
            
            ADDR_PHASE2_PROCESS: begin
                next_state = DATA_PHASE;
            end
            
            DATA_PHASE: begin
                if (sda_reg2 == 1'b0 && scl_reg2 == 1'b0) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 第二级流水线 - 位计数器逻辑
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            bit_count_stage1 <= 3'b000;
            bit_count_stage2 <= 3'b000;
        end else begin
            bit_count_stage2 <= bit_count_stage1;
            
            if (reset_bit_count) begin
                bit_count_stage1 <= 3'b000;
            end else if (scl_reg2 == 1'b1 && state != IDLE) begin
                bit_count_stage1 <= (bit_count_stage1 == 3'b111) ? 3'b000 : bit_count_stage1 + 1'b1;
            end
        end
    end
    
    // 第三级流水线 - I2C数据接收逻辑
    reg scl_rising_edge;
    always @(posedge clk) begin
        if (rst_sync) begin
            scl_rising_edge <= 1'b0;
            shift_reg_stage1 <= 8'h00;
            shift_reg_stage2 <= 8'h00;
        end else begin
            scl_rising_edge <= (scl_reg1 && !scl_reg2); // 检测上升沿
            shift_reg_stage2 <= shift_reg_stage1;
            
            if (scl_rising_edge && state != IDLE) begin
                shift_reg_stage1 <= {shift_reg_stage1[6:0], sda_reg2};
            end
        end
    end
    
    // 第四级流水线 - 地址处理逻辑
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            addr_shift_stage1 <= 10'h0;
            addr_shift_stage2 <= 10'h0;
            addr_shift_stage3 <= 10'h0;
            addr_phase_stage1 <= 1'b0;
            addr_phase_stage2 <= 1'b0;
            addr_phase_stage3 <= 1'b0;
            addr_valid <= 1'b0;
        end else begin
            // 流水线寄存器传递
            addr_shift_stage2 <= addr_shift_stage1;
            addr_shift_stage3 <= addr_shift_stage2;
            addr_phase_stage2 <= addr_phase_stage1;
            addr_phase_stage3 <= addr_phase_stage2;
            
            case(state)
                IDLE: begin
                    addr_phase_stage1 <= 1'b0;
                    addr_valid <= 1'b0;
                end
                
                ADDR_PHASE1_PROCESS: begin
                    addr_shift_stage1[9:2] <= shift_reg_stage2;
                    addr_phase_stage1 <= 1'b1;
                    
                    if (ADDR_MODE == 0) begin
                        // 7位地址模式
                        addr_valid <= (shift_reg_stage2[7:1] == target_addr[6:0]);
                    end
                end
                
                ADDR_PHASE2_PROCESS: begin
                    addr_shift_stage1[1:0] <= shift_reg_stage2[7:6];
                    addr_valid <= (addr_shift_stage3[9:2] == target_addr[9:2] && 
                                  shift_reg_stage2[7:6] == target_addr[1:0]);
                end
                
                DATA_PHASE: begin
                    // 保持之前的地址验证结果
                end
            endcase
        end
    end
    
endmodule