//SystemVerilog
module eth_mii_decoder (
    input wire rx_clk,
    input wire rst_n,
    input wire rx_dv,
    input wire rx_er,
    input wire [3:0] rxd,
    output reg [7:0] data_out,
    output reg data_valid,
    output reg error,
    output reg sfd_detected,
    output reg carrier_sense
);
    // 状态定义
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, SFD = 2'b10, DATA = 2'b11;
    
    // 状态和数据寄存器
    reg [1:0] state, next_state;
    reg [3:0] prev_rxd;
    
    // 流水线寄存器 - 第一级
    reg rx_dv_r, rx_er_r;
    reg [3:0] rxd_r;
    
    // 流水线寄存器 - 用于状态判断的中间变量
    reg is_preamble_byte;
    reg is_sfd_byte;
    reg is_valid_sfd_transition;
    
    // 流水线寄存器 - 第二级输出控制信号
    reg data_valid_next;
    reg sfd_detected_next;
    reg carrier_sense_next;
    reg error_next;
    reg [7:0] data_out_next;
    
    // 输入寄存和基本信号处理 - 切割关键路径第一级
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_dv_r <= 1'b0;
            rx_er_r <= 1'b0;
            rxd_r <= 4'h0;
            prev_rxd <= 4'h0;
            is_preamble_byte <= 1'b0;
            is_sfd_byte <= 1'b0;
            is_valid_sfd_transition <= 1'b0;
        end else begin
            rx_dv_r <= rx_dv;
            rx_er_r <= rx_er;
            rxd_r <= rxd;
            prev_rxd <= rxd_r;
            
            // 预先计算常用条件，减少组合逻辑路径
            is_preamble_byte <= (rxd_r == 4'h5);
            is_sfd_byte <= (rxd_r == 4'hD);
            is_valid_sfd_transition <= (rxd_r == 4'h5 && prev_rxd == 4'hD);
        end
    end
    
    // 状态逻辑 - 切割关键路径中间级
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            next_state <= IDLE;
            data_valid_next <= 1'b0;
            sfd_detected_next <= 1'b0;
            carrier_sense_next <= 1'b0;
            error_next <= 1'b0;
            data_out_next <= 8'h00;
        end else begin
            state <= next_state;
            error_next <= rx_er_r;
            carrier_sense_next <= rx_dv_r;
            data_valid_next <= 1'b0;
            sfd_detected_next <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (rx_dv_r && is_preamble_byte) begin
                        next_state <= PREAMBLE;
                    end else begin
                        next_state <= IDLE;
                    end
                end
                
                PREAMBLE: begin
                    if (rx_dv_r) begin
                        if (is_sfd_byte) begin
                            next_state <= SFD;
                        end else if (!is_preamble_byte) begin
                            next_state <= IDLE;
                        end else begin
                            next_state <= PREAMBLE;
                        end
                    end else begin
                        next_state <= IDLE;
                    end
                end
                
                SFD: begin
                    if (rx_dv_r) begin
                        if (is_valid_sfd_transition) begin
                            next_state <= DATA;
                            sfd_detected_next <= 1'b1;
                            data_out_next[3:0] <= rxd_r;
                        end else begin
                            next_state <= IDLE;
                        end
                    end else begin
                        next_state <= IDLE;
                    end
                end
                
                DATA: begin
                    if (rx_dv_r) begin
                        next_state <= DATA;
                        data_out_next <= {rxd_r, prev_rxd};
                        data_valid_next <= 1'b1;
                    end else begin
                        next_state <= IDLE;
                    end
                end
                
                default: next_state <= IDLE;
            endcase
        end
    end
    
    // 输出寄存器 - 切割关键路径最后一级
    always @(posedge rx_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'h00;
            data_valid <= 1'b0;
            error <= 1'b0;
            sfd_detected <= 1'b0;
            carrier_sense <= 1'b0;
        end else begin
            data_out <= data_out_next;
            data_valid <= data_valid_next;
            error <= error_next;
            sfd_detected <= sfd_detected_next;
            carrier_sense <= carrier_sense_next;
        end
    end
    
endmodule