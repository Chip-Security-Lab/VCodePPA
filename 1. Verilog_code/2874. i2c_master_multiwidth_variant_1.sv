//SystemVerilog IEEE 1364-2005
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
localparam BYTE_COUNT = DATA_WIDTH/8;
reg [2:0] byte_counter;
reg [7:0] shift_reg[0:3]; // Size fixed to maximum of 4 bytes (32 bits)
reg [2:0] bit_cnt;
reg sda_oen;
reg sda_out;
reg [2:0] state;
reg clk_div;

// Define states - Reduced state machine
parameter IDLE = 3'b000;
parameter TRANSFER = 3'b001; // Combined START+TRANSFER
parameter STOP = 3'b010;

// Tri-state control using continuous assignment
assign scl = (state != IDLE) ? clk_div : 1'bz;
assign sda = (sda_oen) ? 1'bz : sda_out;

// Initial register values
initial begin
    byte_counter = 0;
    bit_cnt = 0;
    state = IDLE;
    transfer_done = 0;
    rx_payload = 0;
    for (byte_counter = 0; byte_counter < 4; byte_counter = byte_counter + 1)
        shift_reg[byte_counter] = 0;
    byte_counter = 0;
end

// Optimized Kogge-Stone Adder implementation for 8-bit addition
// Reduced pipeline stages by merging adjacent low-complexity stages
function [7:0] kogge_stone_add;
    input [7:0] a;
    input [7:0] b;
    
    reg [7:0] p_stage0, g_stage0;
    reg [7:0] p_stage1, g_stage1;
    reg [7:0] p_stage2, g_stage2;
    reg [7:0] carry;
    reg [7:0] sum;
    
    begin
        // Stage 0: Generate propagate and generate signals
        p_stage0 = a ^ b;
        g_stage0 = a & b;
        
        // Combined stage - merging previous stage 1 and 2
        p_stage1[0] = p_stage0[0];
        g_stage1[0] = g_stage0[0];
        p_stage1[1] = p_stage0[1];
        g_stage1[1] = g_stage0[1];
        
        for (integer i = 2; i < 8; i = i + 1) begin
            // Combined calculation from previous stages
            p_stage1[i] = p_stage0[i] & p_stage0[i-1] & p_stage0[i-2];
            g_stage1[i] = g_stage0[i] | (p_stage0[i] & g_stage0[i-1]) | 
                         (p_stage0[i] & p_stage0[i-1] & g_stage0[i-2]);
        end
        
        // Final stage - directly from stage 1 to final stage
        p_stage2[0] = p_stage1[0];
        p_stage2[1] = p_stage1[1];
        p_stage2[2] = p_stage1[2];
        p_stage2[3] = p_stage1[3];
        g_stage2[0] = g_stage1[0];
        g_stage2[1] = g_stage1[1];
        g_stage2[2] = g_stage1[2];
        g_stage2[3] = g_stage1[3];
        
        for (integer i = 4; i < 8; i = i + 1) begin
            p_stage2[i] = p_stage1[i] & p_stage1[i-4];
            g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-4]);
        end
        
        // Compute carries
        carry[0] = g_stage2[0];
        for (integer i = 1; i < 8; i = i + 1) begin
            carry[i] = g_stage2[i];
        end
        
        // Compute sum
        sum[0] = p_stage0[0];
        for (integer i = 1; i < 8; i = i + 1) begin
            sum[i] = p_stage0[i] ^ carry[i-1];
        end
        
        kogge_stone_add = sum;
    end
endfunction

// Combined state machine with merged state transitions
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n) begin
        state <= IDLE;
        byte_counter <= 0;
        bit_cnt <= 0;
        transfer_done <= 0;
        sda_oen <= 1;
        sda_out <= 1;
    end else begin
        case (state)
            IDLE: begin
                if (start_transfer) begin
                    state <= TRANSFER;
                    sda_out <= 0; // START condition
                    sda_oen <= 0;
                    bit_cnt <= 0;
                    
                    // Load all bytes from payload based on data width in one step
                    if (DATA_WIDTH >= 8) shift_reg[0] <= tx_payload[7:0];
                    if (DATA_WIDTH >= 16) shift_reg[1] <= tx_payload[15:8];
                    if (DATA_WIDTH >= 24) shift_reg[2] <= tx_payload[23:16];
                    if (DATA_WIDTH >= 32) shift_reg[3] <= tx_payload[31:24];
                    
                    byte_counter <= 0;
                    transfer_done <= 0;
                end else begin
                    sda_oen <= 1;
                    sda_out <= 1;
                    transfer_done <= 0;
                end
            end
            
            TRANSFER: begin
                // Combined transfer logic
                if (bit_cnt < 3'd7) begin
                    bit_cnt <= bit_cnt + 1;
                    sda_out <= shift_reg[byte_counter][7-bit_cnt];
                end else begin
                    bit_cnt <= 0;
                    
                    if (byte_counter < BYTE_COUNT-1) begin
                        byte_counter <= kogge_stone_add(byte_counter, 8'b1);
                    end else begin
                        state <= STOP;
                        sda_out <= 0;
                    end
                end
            end
            
            STOP: begin
                sda_out <= 1; // STOP condition
                state <= IDLE;
                transfer_done <= 1;
                
                // Consolidate receive payload in one step
                if (DATA_WIDTH >= 8) rx_payload[7:0] <= shift_reg[0];
                if (DATA_WIDTH >= 16) rx_payload[15:8] <= shift_reg[1];
                if (DATA_WIDTH >= 24) rx_payload[23:16] <= shift_reg[2];
                if (DATA_WIDTH >= 32) rx_payload[31:24] <= shift_reg[3];
            end
            
            default: state <= IDLE;
        endcase
    end
end

// Clock divider for SCL
always @(posedge clk or negedge rst_async_n) begin
    if (!rst_async_n)
        clk_div <= 1;
    else
        clk_div <= ~clk_div;
end

endmodule