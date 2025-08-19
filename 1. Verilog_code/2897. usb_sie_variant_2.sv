//SystemVerilog
module usb_sie(
    input clk, reset_n,
    input [7:0] rx_data,
    input rx_valid,
    output reg rx_ready,
    output reg [7:0] tx_data,
    output reg tx_valid,
    input tx_ready,
    output reg [1:0] state
);
    // 状态定义 - 使用二进制编码优化面积
    localparam [1:0] IDLE = 2'b00, 
                    RX = 2'b01, 
                    PROCESS = 2'b10, 
                    TX = 2'b11;
                    
    reg [7:0] buffer;
    reg next_rx_ready;
    reg next_tx_valid;
    reg [7:0] next_tx_data;
    reg [7:0] next_buffer;
    reg [1:0] next_state;
    
    // 使用两段式状态机设计，分离组合逻辑和时序逻辑
    // 组合逻辑部分
    always @(*) begin
        // 默认值赋值
        next_state = state;
        next_rx_ready = 1'b0;
        next_tx_valid = tx_valid;
        next_tx_data = tx_data;
        next_buffer = buffer;
        
        case (state)
            IDLE: begin
                // 简化比较链，直接根据rx_valid确定状态转换
                if (rx_valid) begin
                    next_state = RX;
                    next_rx_ready = 1'b1;
                end
            end
            
            RX: begin
                next_buffer = rx_data;
                next_state = PROCESS;
            end
            
            PROCESS: begin
                next_tx_data = buffer;
                next_tx_valid = 1'b1;
                next_state = TX;
            end
            
            TX: begin
                // 优化条件检查
                if (tx_ready) begin
                    next_tx_valid = 1'b0;
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // 时序逻辑部分
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            rx_ready <= 1'b0;
            tx_valid <= 1'b0;
            tx_data <= 8'h00;
            buffer <= 8'h00;
        end else begin
            state <= next_state;
            rx_ready <= next_rx_ready;
            tx_valid <= next_tx_valid;
            tx_data <= next_tx_data;
            buffer <= next_buffer;
        end
    end
endmodule