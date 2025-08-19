module CAN_Interrupt_Controller #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input rst_n,
    input can_rx,
    output reg can_tx,
    input [DATA_WIDTH-1:0] tx_data,
    input tx_data_valid, // 添加缺失信号
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg tx_irq,
    output reg rx_irq,
    output reg error_irq
);
    reg [2:0] state;
    reg [DATA_WIDTH-1:0] tx_shift;
    reg [3:0] bit_cnt;
    reg rx_active;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            tx_irq <= 0;
            rx_irq <= 0;
            error_irq <= 0;
            bit_cnt <= 0;
            can_tx <= 1'b1;
            tx_shift <= 0;
            rx_data <= 0;
            rx_active <= 0;
        end else begin
            case(state)
                0: if (can_rx == 1'b0) begin // 修复 === 为 ==
                    state <= 1;
                    rx_active <= 1;
                    bit_cnt <= 0; // 重置位计数器
                end
                1: begin
                    rx_data <= {rx_data[DATA_WIDTH-2:0], can_rx};
                    if (bit_cnt == DATA_WIDTH-1) begin
                        rx_irq <= 1;
                        state <= 0;
                        rx_active <= 0;
                    end
                    bit_cnt <= bit_cnt + 1;
                end
                2: begin
                    // 添加缺失的状态逻辑
                    can_tx <= tx_shift[DATA_WIDTH-1];
                    tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                    if (bit_cnt == DATA_WIDTH-1) begin
                        tx_irq <= 1;
                        state <= 0;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                default: begin
                    state <= 0; // 返回空闲状态
                end
            endcase
            
            if (tx_data_valid) begin
                tx_shift <= tx_data;
                state <= 2;
                bit_cnt <= 0; // 初始化位计数器
                tx_irq <= 0; // 清除中断标志
            end
        end
    end
endmodule