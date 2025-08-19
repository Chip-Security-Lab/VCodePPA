//SystemVerilog
// SystemVerilog
module CAN_PHY_Interface #(
    parameter TSEG1 = 5,      // Phase Segment 1 length (excluding Sync Seg)
    parameter TSEG2 = 3,      // Phase Segment 2 length
    parameter SJW = 2         // Synchronization Jump Width
)(
    input wire clk,                // System clock
    input wire rst_n,              // Async reset (active low)
    input wire can_rx,             // CAN receive line
    output reg can_tx,             // CAN transmit line
    input wire tx_data,            // Transmit data bit (0 for dominant, 1 for recessive)
    output reg rx_data,            // Received data bit
    input wire tx_enable           // Transmit enable (active high)
);

    // Bit timing state definitions
    localparam SYNC_SEG = 2'b00;
    localparam PROP_SEG = 2'b01;
    localparam PHASE_SEG1 = 2'b10;
    localparam PHASE_SEG2 = 2'b11;

    // Internal registers for bit timing state and data handling
    reg [3:0] bit_timer;        // Counter within the current segment
    reg [1:0] current_seg;      // Current segment state
    reg sample_point;           // Flag indicating the sample point
    reg last_rx;                // Previous state of can_rx for edge detection

    // Helper function to get the length of a segment
    function [3:0] get_seg_limit;
        input [1:0] seg;
        begin
            case(seg)
                SYNC_SEG:   get_seg_limit = 1;     // Sync Segment is always 1 Time Quantum (TQ)
                PROP_SEG:   get_seg_limit = 2;     // Propagation Segment length (example value, adjust as needed)
                PHASE_SEG1: get_seg_limit = TSEG1; // Phase Segment 1 length
                PHASE_SEG2: get_seg_limit = TSEG2; // Phase Segment 2 length
                default:    get_seg_limit = 1;     // Should not happen
            endcase
        end
    endfunction

    //------------------------------------------------------------------------
    // Register Slice: CAN Transmit Output
    // Controls the state of the CAN_TX line based on transmit enable and data.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Recessive state (idle)
        end else begin
            // If tx_enable is high, transmit tx_data (0=Dominant, 1=Recessive).
            // If tx_enable is low, maintain Recessive state.
            can_tx <= tx_enable ? tx_data : 1'b1;
        end
    end

    //------------------------------------------------------------------------
    // Register Slice: CAN Receive Data Output
    // Updates the rx_data output at the sample point.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 1'b1; // Recessive state (idle)
        end else begin
            // Sample the can_rx line when the sample_point flag is active
            if (sample_point) begin
                rx_data <= can_rx;
            end
            // rx_data holds its value until the next sample point
        end
    end

    //------------------------------------------------------------------------
    // Register Slice: CAN Receive Edge Detection
    // Stores the previous value of can_rx to detect edges.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_rx <= 1'b1; // Assume recessive state initially
        end else begin
            // Capture the current can_rx value for edge detection in the next cycle
            last_rx <= can_rx;
        end
    end

    //------------------------------------------------------------------------
    // Register Slice: Bit Timing State Machine
    // Manages the bit timer, segment transitions, and sample point flag.
    // Includes synchronization adjustments.
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 0;
            current_seg <= SYNC_SEG;
            sample_point <= 0;
        end else begin
            // Default next state values
            reg [3:0] next_bit_timer = bit_timer + 1;
            reg [1:0] next_current_seg = current_seg;
            reg next_sample_point = 1'b0; // Sample point is typically low unless explicitly set

            // Check for segment boundary
            if (bit_timer == get_seg_limit(current_seg) - 1) begin
                // End of current segment, transition to the next
                next_bit_timer = 0; // Reset timer for the new segment
                case(current_seg)
                    SYNC_SEG:   next_current_seg = PROP_SEG;
                    PROP_SEG:   next_current_seg = PHASE_SEG1;
                    PHASE_SEG1: begin
                        next_sample_point = 1'b1; // Set sample_point at the end of Phase_Seg1
                        next_current_seg = PHASE_SEG2;
                    end
                    PHASE_SEG2: next_current_seg = SYNC_SEG; // End of bit, loop back to Sync Seg
                    default:    next_current_seg = SYNC_SEG; // Should not happen
                endcase
            end

            // Synchronization handling (adjusts bit_timer)
            // This logic overrides the default next_bit_timer calculation if a sync edge is detected in SYNC_SEG.
            if (current_seg == SYNC_SEG && can_rx != last_rx) begin // Edge detected in Sync Seg
                if (bit_timer > SJW) begin
                    // Resynchronization jump forward (decrease timer value)
                    next_bit_timer = bit_timer - SJW;
                end else begin // bit_timer <= SJW
                     // Resynchronization jump forward (set timer to 0 if jump is larger than current timer value)
                    next_bit_timer = 0;
                end
                // Note: Sync jump only affects the timer, not the segment transition or sample point logic in this implementation.
            end

            // Update state registers
            bit_timer <= next_bit_timer;
            current_seg <= next_current_seg;
            sample_point <= next_sample_point;
        end
    end

endmodule