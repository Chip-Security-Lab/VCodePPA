//SystemVerilog
// SystemVerilog
module mdio_codec (
    input wire clk, rst_n,
    input wire mdio_in, start_op,
    input wire read_mode,
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr, 
    input wire [15:0] wr_data,
    output reg mdio_out, mdio_oe,
    output reg [15:0] rd_data,
    output reg busy, data_valid
);
    // 优化状态编码，使用独热编码减少状态转换逻辑复杂度
    localparam [6:0] IDLE     = 7'b0000001,
                     START    = 7'b0000010,
                     OP       = 7'b0000100,
                     PHY_ADDR = 7'b0001000,
                     REG_ADDR = 7'b0010000,
                     TA       = 7'b0100000,
                     DATA     = 7'b1000000;
                     
    reg [6:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [31:0] shift_reg, next_shift_reg;
    
    // 位计数和状态转换控制信号
    wire state_transition;
    wire [6:0] next_state_bits;
    wire bit_transition_enable;
    
    // 状态转移逻辑和组合输出逻辑
    always @(*) begin
        // 默认值，避免锁存器
        next_state = state;
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        mdio_out = 1'b1;
        mdio_oe = busy;
        
        case (state)
            IDLE: begin
                if (start_op) begin
                    next_state = START;
                    next_bit_count = 6'd0;
                    next_shift_reg = {2'b01, read_mode ? 2'b10 : 2'b01, phy_addr, reg_addr, 
                                     read_mode ? 16'h0 : wr_data};
                end
                mdio_oe = 1'b0;
            end
            
            default: begin
                if (state_transition)
                    next_state = next_state_bits;
                    
                if (bit_transition_enable) begin
                    next_bit_count = bit_count + 6'd1;
                    
                    // 读模式下的TA和DATA状态特殊处理
                    if (read_mode && state == TA) begin
                        mdio_oe = bit_count < 6'd15;
                        mdio_out = 1'b1;
                    end else if (read_mode && state == DATA) begin
                        mdio_oe = 1'b0;
                        next_shift_reg = {shift_reg[30:0], mdio_in};
                    end else begin
                        mdio_out = shift_reg[31];
                        next_shift_reg = {shift_reg[30:0], 1'b0};
                    end
                end
            end
        endcase
    end
    
    // 子模块: 状态转换控制器
    state_transition_controller state_ctrl (
        .state(state),
        .bit_count(bit_count),
        .read_mode(read_mode),
        .state_transition(state_transition),
        .next_state_bits(next_state_bits),
        .bit_transition_enable(bit_transition_enable)
    );
    
    // 时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_count <= 6'd0;
            shift_reg <= 32'd0;
            busy <= 1'b0;
            data_valid <= 1'b0;
            rd_data <= 16'd0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
            
            // 业务逻辑状态处理
            busy_data_controller(
                state, next_state, start_op, 
                bit_count, read_mode, shift_reg,
                busy, data_valid, rd_data
            );
        end
    end
    
    // 任务: 业务状态和数据控制
    task busy_data_controller;
        input [6:0] current_state;
        input [6:0] next_state_in;
        input start_operation;
        input [5:0] bit_counter;
        input read_operation;
        input [31:0] shift_register;
        inout busy_signal;
        inout valid_signal;
        inout [15:0] read_data;
        
        begin
            if (current_state == IDLE) begin
                if (start_operation) begin
                    busy_signal <= 1'b1;
                end else begin
                    valid_signal <= 1'b0;
                end
            end
            
            // 处理读取完成事件
            if ((current_state == DATA) && (bit_counter == 6'd31)) begin
                busy_signal <= 1'b0;
                if (read_operation) begin
                    read_data <= shift_register[15:0];
                    valid_signal <= 1'b1;
                end
            end
        end
    endtask
    
endmodule

// 子模块: 状态转换控制器
module state_transition_controller (
    input wire [6:0] state,
    input wire [5:0] bit_count,
    input wire read_mode,
    output reg state_transition,
    output reg [6:0] next_state_bits,
    output reg bit_transition_enable
);
    // 本地参数定义
    localparam [6:0] IDLE     = 7'b0000001,
                     START    = 7'b0000010,
                     OP       = 7'b0000100,
                     PHY_ADDR = 7'b0001000,
                     REG_ADDR = 7'b0010000,
                     TA       = 7'b0100000,
                     DATA     = 7'b1000000;
                     
    always @(*) begin
        state_transition = 1'b0;
        next_state_bits = IDLE; // 默认值
        bit_transition_enable = 1'b1;
        
        case (state)
            START: begin
                if (bit_count == 6'd1) begin
                    state_transition = 1'b1;
                    next_state_bits = OP;
                end
            end
            
            OP: begin
                if (bit_count == 6'd3) begin
                    state_transition = 1'b1;
                    next_state_bits = PHY_ADDR;
                end
            end
            
            PHY_ADDR: begin
                if (bit_count == 6'd8) begin
                    state_transition = 1'b1;
                    next_state_bits = REG_ADDR;
                end
            end
            
            REG_ADDR: begin
                if (bit_count == 6'd13) begin
                    state_transition = 1'b1;
                    next_state_bits = TA;
                end
            end
            
            TA: begin
                if (bit_count == 6'd15) begin
                    state_transition = 1'b1;
                    next_state_bits = DATA;
                end
            end
            
            DATA: begin
                if (bit_count == 6'd31) begin
                    state_transition = 1'b1;
                    next_state_bits = IDLE;
                end
            end
            
            default: begin
                bit_transition_enable = 1'b0;
            end
        endcase
    end
endmodule