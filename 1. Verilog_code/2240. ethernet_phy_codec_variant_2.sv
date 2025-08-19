//SystemVerilog
module ethernet_phy_codec (
    input wire clk, rst_n,
    input wire tx_clk, rx_clk,
    input wire [7:0] tx_data,
    input wire tx_valid, tx_control,
    output wire [7:0] rx_data,
    output wire rx_valid, rx_control, rx_error,
    inout wire mdio,
    output wire mdc,
    inout wire [3:0] td, rd // Differential pairs for TX/RX
);
    // PCS Sublayer state
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    
    // 内部信号定义
    wire [9:0] encoded_symbol;
    wire [7:0] rx_data_comb;
    wire rx_valid_comb, rx_control_comb, rx_error_comb;
    
    // 内部状态信号
    wire [2:0] tx_state, rx_state;
    
    // 例化TX组合逻辑模块
    tx_encoder tx_encoder_inst (
        .tx_state(tx_state),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .encoded_symbol(encoded_symbol)
    );
    
    // 例化TX时序逻辑模块
    tx_state_machine tx_state_machine_inst (
        .tx_clk(tx_clk),
        .rst_n(rst_n),
        .tx_valid(tx_valid),
        .tx_state(tx_state)
    );
    
    // 例化RX时序逻辑模块
    rx_state_machine rx_state_machine_inst (
        .rx_clk(rx_clk),
        .rst_n(rst_n),
        .rx_data_comb(rx_data_comb),
        .rx_valid_comb(rx_valid_comb),
        .rx_control_comb(rx_control_comb),
        .rx_error_comb(rx_error_comb),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_control(rx_control),
        .rx_error(rx_error),
        .rx_state(rx_state)
    );
    
    // 例化MDC控制模块
    mdc_controller mdc_controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mdc(mdc)
    );
    
    // TD信号驱动 - 简化并行赋值
    assign td = encoded_symbol[3:0];
    
endmodule

// TX编码器 - 组合逻辑模块
module tx_encoder (
    input wire [2:0] tx_state,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output reg [9:0] encoded_symbol
);
    // 状态参数
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    
    // 优化常量表达式，减少逻辑深度
    // 使用并行逻辑而非嵌套结构
    always @(*) begin
        // 预先计算每个状态的输出值
        encoded_symbol = 10'b0101010101; // Default Idle pattern
        
        if (tx_state == PREAMBLE) begin
            encoded_symbol = 10'b1010101010; // Preamble pattern
        end else if (tx_state == DATA) begin
            encoded_symbol = {2'b01, tx_data}; // 简化的8B/10B编码
        end else if (tx_state == EOP) begin
            encoded_symbol = 10'b1111100000; // End pattern
        end
    end
endmodule

// TX状态机 - 时序逻辑模块
module tx_state_machine (
    input wire tx_clk, rst_n,
    input wire tx_valid,
    output reg [2:0] tx_state
);
    // 状态参数
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    
    // 下一状态逻辑，分离组合逻辑和时序逻辑
    reg [2:0] next_state;
    
    // 组合逻辑部分 - 计算下一个状态
    always @(*) begin
        next_state = tx_state; // 默认保持当前状态
        
        case (tx_state)
            IDLE:    next_state = tx_valid ? PREAMBLE : IDLE;
            PREAMBLE: next_state = DATA;
            DATA:    next_state = tx_valid ? DATA : EOP;
            EOP:     next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 时序逻辑部分 - 状态更新
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
        end else begin
            tx_state <= next_state;
        end
    end
endmodule

// RX状态机 - 时序逻辑模块
module rx_state_machine (
    input wire rx_clk, rst_n,
    input wire [7:0] rx_data_comb,
    input wire rx_valid_comb, rx_control_comb, rx_error_comb,
    output reg [7:0] rx_data,
    output reg rx_valid, rx_control, rx_error,
    output reg [2:0] rx_state
);
    // 状态参数
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    
    // 下一状态和输出寄存器
    reg [2:0] next_state;
    reg [7:0] next_rx_data;
    reg next_rx_valid, next_rx_control, next_rx_error;
    
    // 组合逻辑部分 - 计算下一个状态和输出
    always @(*) begin
        // 默认保持当前值
        next_state = rx_state;
        next_rx_data = rx_data;
        next_rx_valid = rx_valid;
        next_rx_control = rx_control;
        next_rx_error = rx_error;
        
        // 简化实现，因为原代码中RX部分未完全实现
        // 在实际应用中，这里会根据rx_state和输入信号更新状态和输出
    end
    
    // 时序逻辑部分 - 状态和输出更新
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            rx_control <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            rx_state <= next_state;
            rx_data <= next_rx_data;
            rx_valid <= next_rx_valid;
            rx_control <= next_rx_control;
            rx_error <= next_rx_error;
        end
    end
endmodule

// MDC控制器 - 时序逻辑模块
module mdc_controller (
    input wire clk, rst_n,
    output reg mdc
);
    // 使用寄存器保存当前状态，分离组合逻辑和时序逻辑
    reg next_mdc;
    
    // 组合逻辑部分
    always @(*) begin
        next_mdc = ~mdc;  // 简单的分频器
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdc <= 1'b0;
        end else begin
            mdc <= next_mdc;
        end
    end
endmodule