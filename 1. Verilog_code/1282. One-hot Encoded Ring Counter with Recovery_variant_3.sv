//SystemVerilog
`timescale 1ns / 1ps

// 顶层模块
module one_hot_ring_counter (
    input  wire       clk,
    input  wire       rst_n,
    output wire [3:0] one_hot
);
    // 内部信号连接
    wire [3:0] next_state;
    wire       reset_state;
    
    // 状态寄存器子模块
    state_register state_reg_inst (
        .clk           (clk),
        .rst_n         (rst_n),
        .next_state    (next_state),
        .current_state (one_hot)
    );
    
    // 状态检测子模块
    state_detector state_detect_inst (
        .current_state (one_hot),
        .reset_state   (reset_state)
    );
    
    // 状态转换逻辑子模块
    next_state_logic next_state_inst (
        .current_state (one_hot),
        .reset_state   (reset_state),
        .next_state    (next_state)
    );
    
endmodule

// 状态寄存器子模块
module state_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] next_state,
    output reg  [3:0] current_state
);
    // 使用同步复位优化时序性能
    always @(posedge clk) begin
        if (!rst_n)
            current_state <= 4'b0001; // 复位状态：仅位0激活
        else
            current_state <= next_state;
    end
endmodule

// 状态检测子模块
module state_detector (
    input  wire [3:0] current_state,
    output wire       reset_state
);
    // 使用归约运算符优化逻辑
    assign reset_state = ~|current_state;
endmodule

// 状态转换逻辑子模块
module next_state_logic (
    input  wire [3:0] current_state,
    input  wire       reset_state,
    output reg  [3:0] next_state
);
    // 使用参数定义状态，提高代码可读性
    localparam [3:0] STATE0 = 4'b0001;
    localparam [3:0] STATE1 = 4'b0010;
    localparam [3:0] STATE2 = 4'b0100;
    localparam [3:0] STATE3 = 4'b1000;
    
    // 使用组合逻辑case语句优化状态转换
    always @(*) begin
        if (reset_state)
            next_state = STATE0;
        else begin
            case (current_state)
                STATE0:   next_state = STATE1;
                STATE1:   next_state = STATE2;
                STATE2:   next_state = STATE3;
                STATE3:   next_state = STATE0;
                default:  next_state = STATE0;
            endcase
        end
    end
endmodule