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

    // Internal state registers
    reg [3:0] bit_timer;        // Bit timer counter
    reg [1:0] current_seg;      // Current segment
    reg sample_point;           // Sample point flag
    reg last_rx;                // Previous receive data

    // Helper function for segment limits
    function automatic [3:0] get_seg_limit;
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

    //------------------------------------------------------------------------
    // Block 1: Bit Timing Control and Synchronization (Optimized)
    // Updates bit_timer, current_seg, and sample_point
    // Restructured logic for path balancing.
    //------------------------------------------------------------------------
    // Combinatorial logic for next state calculation
    wire [3:0] seg_limit = get_seg_limit(current_seg);
    wire end_of_segment = (bit_timer == seg_limit - 1);
    wire is_sync_edge = (current_seg == SYNC_SEG && can_rx != last_rx);

    // Calculate standard next timer value (without sync adjustment)
    wire [3:0] std_next_timer = end_of_segment ? 4'b0 : bit_timer + 1;

    // Calculate synchronization adjustment value
    wire [3:0] sync_adj_val = is_sync_edge ? SJW[3:0] : 4'b0; // Cast SJW to match bit_timer width

    // Calculate next bit timer value, applying sync adjustment and clamping at 0
    wire [3:0] next_bit_timer_val = (std_next_timer >= sync_adj_val) ? (std_next_timer - sync_adj_val) : 4'b0;

    // Calculate next segment value
    wire [1:0] next_current_seg_val;
    assign next_current_seg_val = end_of_segment ? (
        current_seg == SYNC_SEG   ? PROP_SEG :
        current_seg == PROP_SEG   ? PHASE_SEG1 :
        current_seg == PHASE_SEG1 ? PHASE_SEG2 :
        current_seg == PHASE_SEG2 ? SYNC_SEG :
                                    SYNC_SEG
    ) : current_seg;

    // Calculate next sample point value
    wire next_sample_point_val;
    assign next_sample_point_val = end_of_segment ? (
        current_seg == PHASE_SEG1 ? 1'b1 :  // Transitioning to PHASE_SEG2
        current_seg == PHASE_SEG2 ? 1'b0 :  // Transitioning to SYNC_SEG
                                    sample_point // Keep value for other transitions
    ) : sample_point; // Keep value if not end of segment


    // Sequential logic for state registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_timer <= 4'b0;
            current_seg <= SYNC_SEG;
            sample_point <= 1'b0;
        end else begin
            bit_timer <= next_bit_timer_val;
            current_seg <= next_current_seg_val;
            sample_point <= next_sample_point_val;
        end
    end

    //------------------------------------------------------------------------
    // Block 2: last_rx Update
    // Tracks the previous value of can_rx
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_rx <= 1'b1; // Reset last_rx to recessive state
        end else begin
            last_rx <= can_rx;
        end
    end

    //------------------------------------------------------------------------
    // Block 3: Receive Data Sampling
    // Updates rx_data based on sample_point
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 1'b1; // Reset rx_data to recessive state
        end else begin
            if (sample_point) begin
                rx_data <= can_rx;
            end
        end
    end

    //------------------------------------------------------------------------
    // Block 4: Transmit Data Output
    // Controls can_tx based on tx_enable and tx_data
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            can_tx <= 1'b1; // Reset can_tx to recessive state
        end else begin
            can_tx <= tx_enable ? tx_data : 1'b1;
        end
    end

endmodule