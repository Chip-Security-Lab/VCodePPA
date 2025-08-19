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
    parameter IDLE = 3'd0, PREAMBLE = 3'd1, DATA = 3'd2, EOP = 3'd3;
    reg [2:0] tx_state, rx_state;
    reg [9:0] encoded_symbol;
    reg [1:0] disp; // Running disparity control
    
    // 寄存器输入捕获阶段
    reg tx_valid_reg;
    reg [7:0] tx_data_reg;
    
    // 捕获输入信号
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_valid_reg <= 1'b0;
            tx_data_reg <= 8'h00;
        end else begin
            tx_valid_reg <= tx_valid;
            tx_data_reg <= tx_data;
        end
    end
    
    // TX状态机控制 - 使用寄存器后的信号
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= IDLE;
        end else begin
            case (tx_state)
                IDLE: begin
                    if (tx_valid_reg) tx_state <= PREAMBLE;
                end
                PREAMBLE: begin
                    tx_state <= DATA;
                end
                DATA: begin
                    if (!tx_valid_reg) tx_state <= EOP;
                end
                EOP: begin
                    tx_state <= IDLE;
                end
                default: tx_state <= IDLE;
            endcase
        end
    end
    
    // 编码计算组合逻辑
    reg [9:0] symbol_precalc;
    
    always @(*) begin
        case (tx_state)
            IDLE: symbol_precalc = 10'b0101010101; // Idle pattern
            PREAMBLE: symbol_precalc = 10'b1010101010; // Preamble pattern
            DATA: symbol_precalc = {2'b01, tx_data_reg}; // 简化的8B/10B编码
            EOP: symbol_precalc = 10'b1111100000; // End pattern
            default: symbol_precalc = 10'b0101010101;
        endcase
    end
    
    // TX编码逻辑 - 将寄存器移至组合逻辑之后
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_symbol <= 10'h000;
        end else begin
            encoded_symbol <= symbol_precalc;
        end
    end
    
    // 视奇偶失衡计算 - 优化后的分离时序逻辑
    wire [3:0] ones_count;
    assign ones_count = $countones(symbol_precalc);
    
    always @(posedge tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            disp <= 2'b00; // Neutral disparity
        end else if (tx_state == DATA) begin
            // 基于预计算符号的视奇偶失衡
            disp <= (ones_count > 5) ? 2'b01 : 
                   (ones_count < 5) ? 2'b10 : 2'b00;
        end
    end
    
    // RX数据处理前端寄存器
    reg [3:0] rd_reg;
    
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_reg <= 4'h0;
        end else begin
            rd_reg <= rd;
        end
    end
    
    // RX状态机控制
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state <= IDLE;
        end else begin
            // RX状态机转换逻辑（简化实现）
            rx_state <= IDLE; // 简化实现
        end
    end
    
    // RX数据处理
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 8'h00;
        end else begin
            // RX数据处理逻辑（简化实现）
            rx_data <= 8'h00; // 简化实现
        end
    end
    
    // RX控制信号处理
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_valid <= 1'b0;
            rx_control <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            // RX控制信号处理逻辑（简化实现）
            rx_valid <= 1'b0;
            rx_control <= 1'b0;
            rx_error <= 1'b0;
        end
    end
    
    // MDIO控制实现 - 分离阶段
    reg mdc_toggle;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdc_toggle <= 1'b0;
        end else begin
            mdc_toggle <= ~mdc_toggle;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdc <= 1'b0;
        end else begin
            mdc <= mdc_toggle;
        end
    end
    
    // 差分信号驱动实现
    assign td[0] = encoded_symbol[0];
    assign td[1] = encoded_symbol[1];
    assign td[2] = encoded_symbol[2];
    assign td[3] = encoded_symbol[3];
endmodule