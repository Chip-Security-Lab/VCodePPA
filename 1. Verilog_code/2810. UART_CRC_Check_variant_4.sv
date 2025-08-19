//SystemVerilog
module UART_CRC_Check #(
    parameter CRC_WIDTH = 16,
    parameter POLYNOMIAL = 16'h1021
)(
    input  wire                   clk,              // 时钟输入
    input  wire                   rst_n,            // 异步复位，低有效
    input  wire                   tx_start,         // 发送开始信号
    input  wire                   tx_active,        // 发送激活信号
    input  wire                   rx_start,         // 接收开始信号
    input  wire                   rx_active,        // 接收激活信号
    input  wire                   rxd,              // 接收数据输入
    input  wire [CRC_WIDTH-1:0]   rx_crc,           // 接收CRC输入
    output reg                    crc_error,        // CRC错误输出
    input  wire [CRC_WIDTH-1:0]   crc_seed          // CRC初始值
);

// ===================== 发送CRC流水线 ===========================

// Stage 0: 输入同步寄存器
reg tx_start_sync, tx_active_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_start_sync  <= 1'b0;
        tx_active_sync <= 1'b0;
    end else begin
        tx_start_sync  <= tx_start;
        tx_active_sync <= tx_active;
    end
end

// Stage 1: CRC初始值加载或左移
reg [CRC_WIDTH-1:0] crc_tx_stage1;
reg                 tx_valid_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_tx_stage1   <= {CRC_WIDTH{1'b0}};
        tx_valid_stage1 <= 1'b0;
    end else begin
        if (tx_start_sync)
            crc_tx_stage1 <= crc_seed;
        else if (tx_active_sync)
            crc_tx_stage1 <= crc_tx_stage1 << 1;
        else
            crc_tx_stage1 <= crc_tx_stage1;
        tx_valid_stage1 <= tx_start_sync | tx_active_sync;
    end
end

// Stage 2: 多项式异或操作
reg [CRC_WIDTH-1:0] crc_tx_stage2;
reg                 tx_valid_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_tx_stage2   <= {CRC_WIDTH{1'b0}};
        tx_valid_stage2 <= 1'b0;
    end else begin
        if (tx_valid_stage1 && tx_active_sync)
            crc_tx_stage2 <= (crc_tx_stage1 << 1) ^ (POLYNOMIAL & {CRC_WIDTH{crc_tx_stage1[CRC_WIDTH-1]}});
        else
            crc_tx_stage2 <= crc_tx_stage2;
        tx_valid_stage2 <= tx_valid_stage1 && tx_active_sync;
    end
end

// Stage 3: 输出同步寄存器
reg [CRC_WIDTH-1:0] crc_tx_stage3;
reg                 tx_valid_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_tx_stage3   <= {CRC_WIDTH{1'b0}};
        tx_valid_stage3 <= 1'b0;
    end else begin
        crc_tx_stage3   <= crc_tx_stage2;
        tx_valid_stage3 <= tx_valid_stage2;
    end
end

// ===================== 接收CRC流水线 ===========================

// Stage 0: 输入同步寄存器
reg rx_start_sync, rx_active_sync, rxd_sync;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_start_sync  <= 1'b0;
        rx_active_sync <= 1'b0;
        rxd_sync       <= 1'b0;
    end else begin
        rx_start_sync  <= rx_start;
        rx_active_sync <= rx_active;
        rxd_sync       <= rxd;
    end
end

// Stage 1: CRC初始值加载或左移
reg [CRC_WIDTH-1:0] crc_rx_stage1;
reg                 rx_valid_stage1;
reg                 rxd_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_rx_stage1   <= {CRC_WIDTH{1'b0}};
        rx_valid_stage1 <= 1'b0;
        rxd_stage1      <= 1'b0;
    end else begin
        if (rx_start_sync)
            crc_rx_stage1 <= crc_seed;
        else if (rx_active_sync)
            crc_rx_stage1 <= crc_rx_stage1 << 1;
        else
            crc_rx_stage1 <= crc_rx_stage1;
        rx_valid_stage1 <= rx_start_sync | rx_active_sync;
        rxd_stage1      <= rxd_sync;
    end
end

// Stage 2: 多项式和数据异或操作
reg [CRC_WIDTH-1:0] crc_rx_stage2;
reg                 rx_valid_stage2;
reg                 rxd_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_rx_stage2   <= {CRC_WIDTH{1'b0}};
        rx_valid_stage2 <= 1'b0;
        rxd_stage2      <= 1'b0;
    end else begin
        if (rx_valid_stage1 && rx_active_sync)
            crc_rx_stage2 <= (crc_rx_stage1 << 1) ^ (POLYNOMIAL & {CRC_WIDTH{crc_rx_stage1[CRC_WIDTH-1]}}) ^ {CRC_WIDTH{rxd_stage1}};
        else
            crc_rx_stage2 <= crc_rx_stage2;
        rx_valid_stage2 <= rx_valid_stage1 && rx_active_sync;
        rxd_stage2      <= rxd_stage1;
    end
end

// Stage 3: 输出同步寄存器
reg [CRC_WIDTH-1:0] crc_rx_stage3;
reg                 rx_valid_stage3;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_rx_stage3   <= {CRC_WIDTH{1'b0}};
        rx_valid_stage3 <= 1'b0;
    end else begin
        crc_rx_stage3   <= crc_rx_stage2;
        rx_valid_stage3 <= rx_valid_stage2;
    end
end

// ===================== CRC错误检测流水线 ===========================

// Stage 1: 同步rx_crc输入
reg [CRC_WIDTH-1:0] rx_crc_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_crc_stage1 <= {CRC_WIDTH{1'b0}};
    end else if (rx_valid_stage3) begin
        rx_crc_stage1 <= rx_crc;
    end else begin
        rx_crc_stage1 <= rx_crc_stage1;
    end
end

// Stage 2: CRC比较
reg crc_error_stage1;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_error_stage1 <= 1'b0;
    end else if (rx_valid_stage3) begin
        crc_error_stage1 <= (crc_rx_stage3 != rx_crc);
    end else begin
        crc_error_stage1 <= crc_error_stage1;
    end
end

// Stage 3: 输出同步
reg crc_error_stage2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_error_stage2 <= 1'b0;
        crc_error        <= 1'b0;
    end else begin
        crc_error_stage2 <= crc_error_stage1;
        crc_error        <= crc_error_stage2;
    end
end

endmodule