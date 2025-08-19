//SystemVerilog
module rs232_codec #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
) (
    input wire clk, rstn,
    input wire rx, tx_valid,
    input wire [7:0] tx_data,
    output reg tx, rx_valid,
    output reg [7:0] rx_data
);
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    // TX 信号
    wire tx_done;
    wire tx_out;
    
    // RX 信号
    wire rx_sampled;
    wire rx_done;
    wire [7:0] rx_out;
    
    // 直接采样rx输入
    assign rx_sampled = rx;
    
    // 发送器实例化
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_module (
        .clk(clk),
        .rstn(rstn),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx(tx_out),
        .tx_done(tx_done)
    );
    
    // 接收器实例化
    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_module (
        .clk(clk),
        .rstn(rstn),
        .rx(rx_sampled),
        .rx_data(rx_out),
        .rx_valid(rx_done)
    );
    
    // 输出寄存器
    always @(posedge clk) begin
        if (!rstn) begin
            tx <= 1'b1; // 空闲状态为高电平
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
        end else begin
            tx <= tx_out;
            rx_valid <= rx_done;
            if (rx_done) begin
                rx_data <= rx_out;
            end
        end
    end
endmodule

// UART发送器模块
module uart_tx #(
    parameter CLKS_PER_BIT = 434
) (
    input wire clk, rstn,
    input wire tx_valid,
    input wire [7:0] tx_data,
    output reg tx,
    output reg tx_done
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] tx_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] tx_clk_count;
    reg [2:0] tx_bit_idx;
    reg [7:0] tx_shift_reg;
    
    // TX 状态机
    always @(posedge clk) begin
        if (!rstn) begin
            tx_state <= IDLE;
            tx <= 1'b1; // 空闲状态为高电平
            tx_clk_count <= 0;
            tx_bit_idx <= 0;
            tx_done <= 1'b0;
            tx_shift_reg <= 8'h00;
        end else begin
            case (tx_state)
                IDLE: begin
                    tx <= 1'b1; // 保持高电平
                    tx_done <= 1'b0;
                    tx_clk_count <= 0;
                    tx_bit_idx <= 0;
                    
                    if (tx_valid) begin
                        tx_shift_reg <= tx_data;
                        tx_state <= START;
                    end
                end
                
                START: begin
                    tx <= 1'b0; // 开始位为低电平
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= DATA;
                    end
                end
                
                DATA: begin
                    tx <= tx_shift_reg[tx_bit_idx];
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        
                        if (tx_bit_idx < 7) begin
                            tx_bit_idx <= tx_bit_idx + 1;
                        end else begin
                            tx_bit_idx <= 0;
                            tx_state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx <= 1'b1; // 停止位为高电平
                    
                    if (tx_clk_count < CLKS_PER_BIT - 1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_done <= 1'b1;
                        tx_clk_count <= 0;
                        tx_state <= IDLE;
                    end
                end
                
                default: begin
                    tx_state <= IDLE;
                end
            endcase
        end
    end
endmodule

// UART接收器模块
module uart_rx #(
    parameter CLKS_PER_BIT = 434
) (
    input wire clk, rstn,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_valid
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] rx_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] rx_clk_count;
    reg [2:0] rx_bit_idx;
    reg [7:0] rx_shift_reg;
    reg rx_edge_detect;
    reg rx_start_detected;
    reg rx_data_ready;
    
    // 边沿检测逻辑
    always @(posedge clk) begin
        if (!rstn) begin
            rx_edge_detect <= 1'b0;
        end else begin
            rx_edge_detect <= rx;
        end
    end
    
    // RX 状态机
    always @(posedge clk) begin
        if (!rstn) begin
            rx_state <= IDLE;
            rx_clk_count <= 0;
            rx_bit_idx <= 0;
            rx_shift_reg <= 8'h00;
            rx_valid <= 1'b0;
            rx_data <= 8'h00;
            rx_start_detected <= 1'b0;
            rx_data_ready <= 1'b0;
        end else begin
            case (rx_state)
                IDLE: begin
                    rx_valid <= 1'b0;
                    if (!rx && rx_edge_detect) begin
                        rx_state <= START;
                        rx_clk_count <= 0;
                        rx_start_detected <= 1'b1;
                    end
                end
                
                START: begin
                    if (rx_clk_count == CLKS_PER_BIT/2 - 1) begin
                        if (!rx) begin
                            rx_state <= DATA;
                            rx_clk_count <= 0;
                            rx_bit_idx <= 0;
                        end else begin
                            rx_state <= IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                
                DATA: begin
                    if (rx_clk_count == CLKS_PER_BIT - 1) begin
                        rx_clk_count <= 0;
                        rx_shift_reg[rx_bit_idx] <= rx;
                        
                        if (rx_bit_idx == 7) begin
                            rx_state <= STOP;
                            rx_data_ready <= 1'b1;
                        end else begin
                            rx_bit_idx <= rx_bit_idx + 1;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                
                STOP: begin
                    if (rx_clk_count == CLKS_PER_BIT - 1) begin
                        if (rx) begin
                            rx_state <= IDLE;
                            rx_valid <= 1'b1;
                            rx_data <= rx_shift_reg;
                        end else begin
                            rx_state <= IDLE;
                        end
                        rx_data_ready <= 1'b0;
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end
                end
                
                default: begin
                    rx_state <= IDLE;
                end
            endcase
        end
    end
endmodule