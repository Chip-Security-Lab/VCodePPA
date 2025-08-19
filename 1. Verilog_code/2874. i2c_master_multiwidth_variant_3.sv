//SystemVerilog
`timescale 1ns / 1ps
module i2c_master_multiwidth #(
    parameter DATA_WIDTH = 8,  // Supports 8/16/32
    parameter PACKET_MODE = 0  // 0-single packet 1-continuous packet
)(
    input clk,
    input rst_async_n,         // Asynchronous reset
    input start_transfer,
    input [DATA_WIDTH-1:0] tx_payload,
    output reg [DATA_WIDTH-1:0] rx_payload,
    inout wire sda,
    output wire scl,
    output reg transfer_done
);
// Unique feature: Dynamic bit width + packet mode
localparam BYTE_COUNT = DATA_WIDTH>>3;  
reg [1:0] byte_counter;                 
reg [7:0] shift_reg[0:3];               // Size fixed to maximum of 4 bytes (32 bits)
reg [2:0] bit_cnt;
reg sda_oen;
reg sda_out;
reg [2:0] state;
reg clk_div;
reg start_transfer_reg;
reg [DATA_WIDTH-1:0] tx_payload_reg;

// Define states - 使用独热码编码
localparam IDLE     = 3'b001;
localparam START    = 3'b010;
localparam TRANSFER = 3'b100;
localparam STOP     = 3'b011;

// 输入寄存器化 - 前向寄存器重定时的关键步骤
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        start_transfer_reg <= 1'b0;
        tx_payload_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        start_transfer_reg <= start_transfer;
        tx_payload_reg <= tx_payload;
    end
end

// Tri-state control using continuous assignment
assign scl = (state == IDLE) ? 1'bz : clk_div;
assign sda = sda_oen ? 1'bz : sda_out;

// 初始化逻辑
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        byte_counter <= 0;
        bit_cnt <= 0;
        state <= IDLE;
        transfer_done <= 0;
        rx_payload <= 0;
        shift_reg[0] <= 0;
        shift_reg[1] <= 0;
        shift_reg[2] <= 0;
        shift_reg[3] <= 0;
        sda_oen <= 1'b1;
        sda_out <= 1'b1;
        clk_div <= 1'b1;
    end
end

// Main logic with optimized state transitions
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        state <= IDLE;
        byte_counter <= 0;
        bit_cnt <= 0;
        transfer_done <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (start_transfer_reg) begin  // 使用寄存器化的输入信号
                    state <= START;
                    // 数据加载逻辑也使用寄存器化的输入
                    shift_reg[0] <= (DATA_WIDTH > 8) ? tx_payload_reg[7:0] : tx_payload_reg;
                end
            end
            // Additional states would be implemented here
            default: state <= IDLE;
        endcase
    end
end

// 字节处理逻辑
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        byte_counter <= 0;
    end else if (state == TRANSFER && bit_cnt == 3'd7 && DATA_WIDTH > 8) begin
        if (byte_counter < BYTE_COUNT-1) begin
            byte_counter <= byte_counter + 1'b1;
            
            // 使用寄存器化的输入数据
            case (byte_counter)
                2'd0: shift_reg[1] <= tx_payload_reg[15:8];
                2'd1: shift_reg[2] <= tx_payload_reg[23:16];
                2'd2: shift_reg[3] <= tx_payload_reg[31:24];
                default: shift_reg[0] <= tx_payload_reg[7:0];
            endcase
        end
    end
end
endmodule