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

    // Combinational logic to determine segment limit and limit-1
    reg [3:0] seg_limit;
    reg [3:0] seg_limit_minus_1;

    always_comb begin
        case(current_seg)
            SYNC_SEG:   seg_limit = 1;   // Fixed 1 clock
            PROP_SEG:   seg_limit = 2;   // Fixed propagation segment
            PHASE_SEG1: seg_limit = TSEG1;
            PHASE_SEG2: seg_limit = TSEG2;
            default:    seg_limit = 1;
        endcase
        // Calculate limit - 1 for the timer comparison
        seg_limit_minus_1 = seg_limit - 1;
    end

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
            // Increment timer if not at limit-1, otherwise reset and change segment
            if (bit_timer < seg_limit_minus_1) begin // Optimized comparison using pre-calculated limit-1
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
            // Adjust bit timing upon edge detection in SYNC_SEG
            if (current_seg == SYNC_SEG) begin
                if (can_rx != last_rx) begin // Edge detection
                    // Optimized comparison and conditional assignment using ternary operator
                    // If bit_timer > SJW, subtract SJW; otherwise, reset to 0.
                    // This replaces the original if/else block and the two's complement subtraction.
                    bit_timer <= (bit_timer > SJW) ? (bit_timer - SJW) : 0;
                end
            end
        end
    end
endmodule