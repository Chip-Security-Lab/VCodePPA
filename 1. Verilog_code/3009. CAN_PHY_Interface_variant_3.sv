//SystemVerilog
// SystemVerilog
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

    // State registers
    reg [3:0] bit_timer;        // Bit timer counter
    reg [1:0] current_seg;      // Current segment
    reg sample_point;           // Sample point flag (state)
    reg last_rx;                // Previous receive data

    // Pipelined registers for next state calculation results (Stage 1 output)
    reg [3:0] p1_next_bit_timer;
    reg [1:0] p1_next_current_seg;
    reg p1_next_sample_point;
    reg p1_sample_point_active_trigger; // Flag indicating if sample_point transition to active was calculated

    // Combinational logic to calculate next state (Stage 1)
    wire [3:0] current_seg_limit;
    wire current_timer_at_limit;
    wire sync_edge_detected_comb;

    // Helper function for segment limits (remains combinational)
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

    // Calculate combinational intermediate values based on current state
    assign current_seg_limit = get_seg_limit(current_seg);
    assign current_timer_at_limit = (bit_timer == current_seg_limit - 1);
    assign sync_edge_detected_comb = (current_seg == SYNC_SEG && can_rx != last_rx);

    // Combinational block calculates intended next state values (Stage 1)
    // Restructure comparison chain for potentially better PPA
    always @(*) begin
        // Default assignments (values if no specific condition met)
        p1_next_bit_timer = bit_timer;
        p1_next_current_seg = current_seg;
        p1_next_sample_point = sample_point;
        p1_sample_point_active_trigger = 1'b0;

        // --- Logic for p1_next_bit_timer ---
        if (sync_edge_detected_comb) begin
            // Sync override: Adjust bit timing (not exceeding SJW)
            if (bit_timer > SJW) begin
                // Use two's complement subtraction: A - B = A + (~B) + 1
                p1_next_bit_timer = bit_timer + (~SJW) + 1;
            end else begin
                p1_next_bit_timer = 0; // Timer cannot go below 0
            end
        end else if (!current_timer_at_limit) begin
            // Timer increment
            p1_next_bit_timer = bit_timer + 1;
        end else begin // current_timer_at_limit && !sync_edge_detected_comb
            // Timer wrap
            p1_next_bit_timer = 0;
        end

        // --- Logic for p1_next_current_seg, p1_next_sample_point, p1_sample_point_active_trigger ---
        // These only change when timer wraps AND no sync edge is detected
        if (current_timer_at_limit && !sync_edge_detected_comb) begin
            case(current_seg)
                SYNC_SEG: begin
                    p1_next_current_seg = PROP_SEG;
                    p1_next_sample_point = 1'b0; // Ensure sample_point is low before PHASE_SEG1 starts
                end
                PROP_SEG: begin
                    p1_next_current_seg = PHASE_SEG1;
                    p1_next_sample_point = 1'b0; // Ensure sample_point is low before PHASE_SEG1 starts
                end
                PHASE_SEG1: begin
                    p1_next_current_seg = PHASE_SEG2;
                    p1_next_sample_point = 1'b1; // Sample point active in next cycle
                    p1_sample_point_active_trigger = 1'b1; // Flag for this cycle's calculation
                end
                PHASE_SEG2: begin
                    p1_next_current_seg = SYNC_SEG;
                    p1_next_sample_point = 1'b0; // Sample point inactive in next cycle
                end
                default: begin
                    p1_next_current_seg = SYNC_SEG;
                    p1_next_sample_point = 1'b0;
                end
            endcase
        end
        // Else (timer increment OR sync detected), p1_next_current_seg, p1_next_sample_point, p1_sample_point_active_trigger
        // remain at their default values (current_seg, sample_point, 0) which is correct according to the original logic.

    end // end always @(*)

    // Sequential logic (Stage 2: Register next state and update state)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // State registers reset
            bit_timer <= 0;
            current_seg <= SYNC_SEG;
            sample_point <= 0;
            last_rx <= 1'b1;
            can_tx <= 1'b1;
            rx_data <= 1'b1;

            // Pipeline registers reset
            p1_next_bit_timer <= 0;
            p1_next_current_seg <= SYNC_SEG;
            p1_next_sample_point <= 0;
            p1_sample_point_active_trigger <= 0;

        end else begin
            // Update state based on registered next state values from Stage 1 calculation (previous cycle)
            bit_timer <= p1_next_bit_timer;
            current_seg <= p1_next_current_seg;
            sample_point <= p1_next_sample_point; // Sample point state for the *next* cycle

            // Other state updates
            last_rx <= can_rx; // Previous receive data

            // Transmit logic (independent of bit timing state machine pipeline)
            can_tx <= tx_enable ? tx_data : 1'b1;

            // Receive sampling logic
            // Sample rx_data based on the sample_point transition calculated *one cycle ago*.
            // p1_sample_point_active_trigger flag indicates if sample_point was set high in the previous cycle's calculation.
            if (p1_sample_point_active_trigger) begin
                rx_data <= can_rx; // Sample can_rx in the cycle *after* sample_point is active
            end
        end
    end // end always @(posedge clk ...)

endmodule