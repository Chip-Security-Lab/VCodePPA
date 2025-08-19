//SystemVerilog
module i2c_10bit_addr #(
    parameter ADDR_MODE = 0  // 0-7bit, 1-10bit
)(
    input  wire        clk,
    input  wire        rst_sync,
    inout  wire        sda,
    inout  wire        scl,
    input  wire [9:0]  target_addr,
    output reg         addr_valid
);
    // =========================================================================
    // 状态定义 - 清晰的状态机结构
    // =========================================================================
    localparam IDLE       = 2'b00;
    localparam ADDR_PHASE1 = 2'b01;
    localparam ADDR_PHASE2 = 2'b10;
    localparam DATA_PHASE  = 2'b11;
    
    // =========================================================================
    // 内部信号定义 - 分离控制路径和数据路径
    // =========================================================================
    // 控制路径信号
    reg [1:0]  state_r;           // 当前状态寄存器
    reg [1:0]  next_state;        // 下一状态逻辑
    reg        update_addr_valid; // 地址有效信号更新标志
    reg        next_addr_valid;   // 下一周期地址有效值
    reg        scl_rising_edge;   // SCL上升沿检测
    reg        scl_prev;          // 前一周期SCL值
    
    // 数据路径信号
    reg [9:0]  addr_buffer_r;     // 地址缓存寄存器
    reg [7:0]  shift_reg_r;       // 移位寄存器
    reg [2:0]  bit_counter_r;     // 位计数器
    reg        is_first_byte_10bit_r; // 10位地址第一字节标志
    
    // 起始条件检测
    wire       start_condition = (sda == 1'b0 && scl == 1'b1 && state_r == IDLE);
    
    // 字节接收完成标志
    wire       byte_complete = (bit_counter_r == 3'b111 && scl_rising_edge);
    
    // =========================================================================
    // SCL上升沿检测 - 改进的时序控制
    // =========================================================================
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            scl_prev <= 1'b1;
            scl_rising_edge <= 1'b0;
        end else begin
            scl_prev <= scl;
            scl_rising_edge <= (scl == 1'b1 && scl_prev == 1'b0);
        end
    end
    
    // =========================================================================
    // 数据路径 - 寄存器级联结构
    // =========================================================================
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            shift_reg_r <= 8'h0;
            bit_counter_r <= 3'b000;
            addr_buffer_r <= 10'h0;
            is_first_byte_10bit_r <= 1'b0;
        end else begin
            // 位计数器和移位寄存器逻辑
            if (state_r != IDLE && scl_rising_edge) begin
                // 在SCL上升沿采样数据
                shift_reg_r <= {shift_reg_r[6:0], sda};
                bit_counter_r <= bit_counter_r + 1'b1;
            end else if (state_r == IDLE || byte_complete) begin
                // 重置位计数器
                bit_counter_r <= 3'b000;
            end
            
            // 地址缓存逻辑
            if (state_r == ADDR_PHASE1 && byte_complete) begin
                // 存储第一个地址字节
                addr_buffer_r[9:2] <= shift_reg_r;
                
                // 检查是否为10位地址模式的首字节
                if (ADDR_MODE == 1) begin
                    is_first_byte_10bit_r <= (shift_reg_r[7:3] == 5'b11110);
                end
            end else if (state_r == ADDR_PHASE2 && byte_complete) begin
                // 存储第二个地址字节的低两位 (10位模式)
                addr_buffer_r[1:0] <= shift_reg_r[7:6];
            end
        end
    end
    
    // =========================================================================
    // 控制路径 - 状态转换和控制逻辑
    // =========================================================================
    // 状态转换逻辑
    always @(*) begin
        // 默认值 - 防止锁存器
        next_state = state_r;
        update_addr_valid = 1'b0;
        next_addr_valid = addr_valid;
        
        case(state_r)
            IDLE: begin
                if (start_condition) begin
                    next_state = ADDR_PHASE1;
                    update_addr_valid = 1'b1;
                    next_addr_valid = 1'b0;
                end
            end
            
            ADDR_PHASE1: begin
                if (byte_complete) begin
                    if (ADDR_MODE == 0) begin
                        // 7位地址模式
                        next_state = DATA_PHASE;
                        update_addr_valid = 1'b1;
                        next_addr_valid = (shift_reg_r[7:1] == target_addr[6:0]);
                    end else begin
                        // 10位地址模式
                        if (shift_reg_r[7:3] == 5'b11110) begin
                            next_state = ADDR_PHASE2;
                        end else begin
                            next_state = IDLE;
                        end
                    end
                end
            end
            
            ADDR_PHASE2: begin
                if (byte_complete) begin
                    next_state = DATA_PHASE;
                    update_addr_valid = 1'b1;
                    next_addr_valid = (addr_buffer_r[9:2] == target_addr[9:2] && 
                                       shift_reg_r[7:6] == target_addr[1:0]);
                end
            end
            
            DATA_PHASE: begin
                if (sda == 1'b0 && scl == 1'b0) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // =========================================================================
    // 寄存器更新 - 流水线控制路径
    // =========================================================================
    always @(posedge clk or posedge rst_sync) begin
        if (rst_sync) begin
            state_r <= IDLE;
            addr_valid <= 1'b0;
        end else begin
            state_r <= next_state;
            
            if (update_addr_valid) begin
                addr_valid <= next_addr_valid;
            end
        end
    end

endmodule