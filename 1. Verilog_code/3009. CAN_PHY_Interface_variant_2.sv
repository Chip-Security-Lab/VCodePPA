//SystemVerilog
module CAN_PHY_Interface #(
    parameter TSEG1 = 5,      // Phase Segment 1
    parameter TSEG2 = 3,      // Phase Segment 2
    parameter SJW = 2         // Synchronization Jump Width
)(
    input wire clk,                // System clock
    input wire rst_n,              // Async reset
    input wire can_rx,             // CAN receive line
    output reg can_tx,             // CAN transmit line
    input wire tx_data,            // Transmit data bit
    output reg rx_data,            // Received data bit
    input wire tx_enable           // Transmit enable
);
    // Bit timing state definitions
    localparam SYNC_SEG = 2'b00;
    localparam PROP_SEG = 2'b01;
    localparam PHASE_SEG1 = 2'b10;
    localparam PHASE_SEG2 = 2'b11;

    reg [3:0] bit_timer;        // Bit timer counter
    reg [1:0] current_seg;      // Current segment
    reg sample_point;           // Sample point flag
    reg last_rx;                // Previous receive data
    
    // Helper function for segment limits
    function [3:0] get_seg_limit;
        input [1:0] seg;
        begin
            case(seg)
                SYNC_SEG:   get_seg_limit = 1;   // Fixed 1 clock
                PROP_SEG:   get_seg_limit = 2;   // Fixed propagation segment
                PHASE_SEG1: get_seg_limit = TSEG1;
                PHASE_SEG2: get_seg_limit = TSEG2;
                default:    get_seg_limit = 1;
            endcase
        end
    endfunction

    // Wires for conditional summation subtraction (bit_timer - SJW)
    // Calculate bit_timer + (~SJW) + 1 using a 5-bit adder to get carry
    wire [4:0] diff_sum = bit_timer + (~SJW[3:0]) + 1'b1;
    wire [3:0] diff_result = diff_sum[3:0]; // Result of subtraction if positive
    wire carry_out = diff_sum[4];          // Carry indicates bit_timer >= SJW

    // Bit timing control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 0;
            current_seg <= SYNC_SEG;
            sample_point <= 0;
            last_rx <= 1'b1;
            can_tx <= 1'b1;
            rx_data <= 1'b1;
        end else begin
            last_rx <= can_rx;
            
            // Bit timer counter logic
            if (bit_timer < get_seg_limit(current_seg)-1) begin
                bit_timer <= bit_timer + 1;
            end else begin
                bit_timer <= 0;
                case(current_seg)
                    SYNC_SEG: current_seg <= PROP_SEG;
                    PROP_SEG: current_seg <= PHASE_SEG1;
                    PHASE_SEG1: begin
                        sample_point <= 1'b1;
                        current_seg <= PHASE_SEG2;
                    end
                    PHASE_SEG2: begin
                        sample_point <= 1'b0;
                        current_seg <= SYNC_SEG;
                    end
                    default: current_seg <= SYNC_SEG;
                endcase
            end

            // Receive sampling logic
            if (sample_point) begin
                rx_data <= can_rx;
            end

            // Transmit logic
            can_tx <= tx_enable ? tx_data : 1'b1;

            // Synchronization handling
            if (current_seg == SYNC_SEG) begin
                if (can_rx != last_rx) begin // Edge detection
                    // Adjust bit timing (not exceeding SJW) using conditional summation subtraction
                    // Original logic: if (bit_timer > SJW) bit_timer <= bit_timer - SJW; else bit_timer <= 0;
                    
                    // Equivalent logic using addition and carry:
                    // bit_timer > SJW is true if carry_out is 1 AND diff_result is not 0
                    if (carry_out && (diff_result != 4'b0)) begin 
                        bit_timer <= diff_result; // bit_timer - SJW
                    end else begin // bit_timer <= SJW
                        bit_timer <= 0;
                    end
                end
            end
        end
    end
endmodule