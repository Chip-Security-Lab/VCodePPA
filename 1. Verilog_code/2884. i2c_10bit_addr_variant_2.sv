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
    reg [9:0] addr_shift_stage1;
    reg [9:0] addr_shift_stage2;
    reg addr_phase_stage1;
    reg addr_phase_stage2;
    reg [7:0] shift_reg;
    reg [7:0] shift_reg_stage1;
    
    // 定义状态
    localparam IDLE = 3'b000;
    localparam ADDR_PHASE1_START = 3'b001;
    localparam ADDR_PHASE1_PROCESS = 3'b010;
    localparam ADDR_PHASE2_START = 3'b011;
    localparam ADDR_PHASE2_PROCESS = 3'b100;
    localparam DATA_PHASE = 3'b101;
    
    reg [2:0] state;
    reg [2:0] next_state;
    
    // I2C条件检测流水线级
    reg sda_ff1, sda_ff2, scl_ff1, scl_ff2;
    wire start_condition;
    wire stop_condition;
    
    // 地址比较流水线级
    reg [9:0] target_addr_stage1;
    reg [9:0] target_addr_stage2;
    reg addr_compare_stage1;
    reg addr_compare_stage2;
    
    // 采样流水线
    reg [2:0] bit_count;
    reg [2:0] bit_count_next;
    reg scl_edge_detect;
    reg scl_prev;
    
    // 检测起始和停止条件
    assign start_condition = scl_ff2 && !sda_ff1 && sda_ff2;
    assign stop_condition = scl_ff2 && sda_ff1 && !sda_ff2;
    
    // 合并所有posedge clk的always块
    always @(posedge clk) begin
        if (rst_sync) begin
            // 重置I2C信号检测流水线
            sda_ff1 <= 1'b1;
            sda_ff2 <= 1'b1;
            scl_ff1 <= 1'b1;
            scl_ff2 <= 1'b1;
            scl_prev <= 1'b1;
            scl_edge_detect <= 1'b0;
            
            // 重置状态机
            state <= IDLE;
            
            // 重置地址寄存器
            addr_shift_stage1 <= 10'h0;
            addr_shift_stage2 <= 10'h0;
            addr_phase_stage1 <= 1'b0;
            addr_phase_stage2 <= 1'b0;
            
            // 重置地址比较流水线
            target_addr_stage1 <= 10'h0;
            target_addr_stage2 <= 10'h0;
            addr_compare_stage1 <= 1'b0;
            addr_compare_stage2 <= 1'b0;
            addr_valid <= 1'b0;
            
            // 重置位计数和移位寄存器
            shift_reg <= 8'h0;
            shift_reg_stage1 <= 8'h0;
            bit_count <= 3'b000;
            bit_count_next <= 3'b000;
        end else begin
            // I2C信号流水线更新
            sda_ff1 <= sda;
            sda_ff2 <= sda_ff1;
            scl_ff1 <= scl;
            scl_ff2 <= scl_ff1;
            scl_prev <= scl_ff2;
            
            // 检测SCL上升沿
            scl_edge_detect <= scl_ff2 && !scl_prev;
            
            // 状态机更新
            state <= next_state;
            
            // 地址寄存器更新
            if (state == ADDR_PHASE1_PROCESS) begin
                addr_shift_stage1[9:2] <= shift_reg;
                addr_phase_stage1 <= 1'b1;
            end else if (state == ADDR_PHASE2_PROCESS) begin
                addr_shift_stage1[1:0] <= shift_reg[7:6];
            end
            
            // 地址比较流水线
            addr_shift_stage2 <= addr_shift_stage1;
            addr_phase_stage2 <= addr_phase_stage1;
            target_addr_stage1 <= target_addr;
            target_addr_stage2 <= target_addr_stage1;
            
            if (state == ADDR_PHASE1_PROCESS && ADDR_MODE == 0) begin
                // 7位地址模式比较流水线
                addr_compare_stage1 <= (shift_reg[7:1] == target_addr_stage1[6:0]);
            end else if (state == ADDR_PHASE2_PROCESS) begin
                // 10位地址模式比较流水线
                addr_compare_stage1 <= (addr_shift_stage1[9:2] == target_addr_stage1[9:2] && 
                                      shift_reg[7:6] == target_addr_stage1[1:0]);
            end
            
            // 最终地址验证
            addr_compare_stage2 <= addr_compare_stage1;
            
            if ((state == DATA_PHASE && ADDR_MODE == 0) || 
                (state == DATA_PHASE && ADDR_MODE == 1)) begin
                addr_valid <= addr_compare_stage2;
            end else if (state == IDLE) begin
                addr_valid <= 1'b0;
            end
            
            // 位计数和移位寄存器逻辑
            shift_reg_stage1 <= shift_reg;
            
            if (scl_edge_detect && (state != IDLE)) begin
                shift_reg <= {shift_reg[6:0], sda_ff2};
                bit_count <= bit_count_next;
                
                if (bit_count == 3'b111) begin
                    bit_count_next <= 3'b000;
                end else begin
                    bit_count_next <= bit_count + 1;
                end
            end else if (state == IDLE) begin
                bit_count <= 3'b000;
                bit_count_next <= 3'b000;
            end
        end
    end
    
    // 保留组合逻辑部分单独的always块
    always @(*) begin
        next_state = state;
        
        case(state)
            IDLE: begin
                if (start_condition) begin
                    next_state = ADDR_PHASE1_START;
                end
            end
            
            ADDR_PHASE1_START: begin
                next_state = ADDR_PHASE1_PROCESS;
            end
            
            ADDR_PHASE1_PROCESS: begin
                if (bit_count == 3'b111 && scl_edge_detect) begin
                    if (ADDR_MODE == 0) begin
                        // 7位地址模式
                        next_state = DATA_PHASE;
                    end else begin
                        // 10位地址模式
                        if (shift_reg[7:3] == 5'b11110) begin
                            next_state = ADDR_PHASE2_START;
                        end else begin
                            next_state = IDLE;
                        end
                    end
                end
            end
            
            ADDR_PHASE2_START: begin
                next_state = ADDR_PHASE2_PROCESS;
            end
            
            ADDR_PHASE2_PROCESS: begin
                if (bit_count == 3'b111 && scl_edge_detect) begin
                    next_state = DATA_PHASE;
                end
            end
            
            DATA_PHASE: begin
                if (stop_condition) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule