//SystemVerilog
module ethernet_phy_codec (
    input wire clk, rst_n,
    input wire tx_clk, rx_clk,
    input wire [7:0] tx_data,
    input wire tx_valid, tx_control,
    output reg [7:0] rx_data,
    output reg rx_valid, rx_control, rx_error,
    inout wire mdio,
    output reg mdc,
    inout wire [3:0] td, rd // Differential pairs for TX/RX
);
    // PCS Sublayer state
    localparam IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    reg [2:0] tx_state, rx_state;
    reg [9:0] encoded_symbol;
    reg [1:0] disp; // Running disparity control
    
    // 优化的常量定义
    localparam [9:0] IDLE_PATTERN     = 10'b0101010101;
    localparam [9:0] PREAMBLE_PATTERN = 10'b1010101010;
    localparam [9:0] EOP_PATTERN      = 10'b1111100000;
    
    // 扁平化优化的TX datapath
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
            disp <= 2'b00; // Neutral disparity
            encoded_symbol <= 10'h000;
        end else if (tx_state == IDLE && !tx_valid) begin
            encoded_symbol <= IDLE_PATTERN;
            tx_state <= IDLE;
        end else if (tx_state == IDLE && tx_valid) begin
            encoded_symbol <= IDLE_PATTERN;
            tx_state <= PREAMBLE;
        end else if (tx_state == PREAMBLE) begin
            encoded_symbol <= PREAMBLE_PATTERN;
            tx_state <= DATA;
        end else if (tx_state == DATA && tx_valid) begin
            encoded_symbol <= {2'b01, tx_data}; // 简化的8B/10B编码
            tx_state <= DATA;
        end else if (tx_state == DATA && !tx_valid) begin
            encoded_symbol <= {2'b01, tx_data}; // 简化的8B/10B编码
            tx_state <= EOP;
        end else if (tx_state == EOP) begin
            encoded_symbol <= EOP_PATTERN;
            tx_state <= IDLE;
        end else begin
            tx_state <= IDLE;
            encoded_symbol <= IDLE_PATTERN;
        end
    end
    
    // 扁平化优化的RX datapath实现
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
            rx_data <= 8'h00;
            rx_valid <= 1'b0;
            rx_control <= 1'b0;
            rx_error <= 1'b0;
        end else if (rx_state == IDLE) begin
            // 扁平化处理IDLE状态逻辑
            rx_valid <= 1'b0;
            if (rd == IDLE_PATTERN[3:0]) begin
                rx_state <= PREAMBLE;
                rx_control <= 1'b1;
            end else begin
                rx_state <= IDLE;
                rx_control <= 1'b0;
            end
            rx_error <= 1'b0;
        end else if (rx_state == PREAMBLE) begin
            // 扁平化处理PREAMBLE状态逻辑
            rx_valid <= 1'b0;
            rx_control <= 1'b1;
            rx_state <= DATA;
            rx_error <= 1'b0;
        end else if (rx_state == DATA) begin
            // 扁平化处理DATA状态逻辑
            rx_valid <= 1'b1;
            rx_control <= 1'b0;
            rx_data <= rd[3:0] == EOP_PATTERN[3:0] ? 8'h00 : {4'b0000, rd[3:0]};
            rx_state <= rd[3:0] == EOP_PATTERN[3:0] ? EOP : DATA;
            rx_error <= 1'b0;
        end else if (rx_state == EOP) begin
            // 扁平化处理EOP状态逻辑
            rx_valid <= 1'b0;
            rx_control <= 1'b1;
            rx_state <= IDLE;
            rx_error <= 1'b0;
        end else begin
            // 默认处理
            rx_state <= IDLE;
            rx_valid <= 1'b0;
            rx_control <= 1'b0;
            rx_error <= 1'b1;
        end
    end
    
    // 扁平化优化的MDIO控制实现
    reg mdc_div;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdc <= 1'b0;
            mdc_div <= 1'b0;
        end else if (mdc_div) begin
            mdc_div <= 1'b0;
            mdc <= ~mdc;
        end else begin
            mdc_div <= 1'b1;
            mdc <= mdc;
        end
    end
    
    // 优化的差分信号驱动实现
    assign td[0] = encoded_symbol[0];
    assign td[1] = encoded_symbol[1];
    assign td[2] = encoded_symbol[2];
    assign td[3] = encoded_symbol[3];
endmodule