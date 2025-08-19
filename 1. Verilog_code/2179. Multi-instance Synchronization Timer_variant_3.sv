//SystemVerilog
//===========================================================================
// Module: sync_multi_timer
// Standard: IEEE 1364-2005
// Description: Pipelined synchronous multi-timer with master-slave clock domains
//===========================================================================
module sync_multi_timer (
    input  wire        master_clk,  // Master clock domain
    input  wire        slave_clk,   // Slave clock domain
    input  wire        reset,       // System reset
    input  wire        sync_en,     // Synchronization enable
    output reg  [31:0] master_count, // Master counter value
    output reg  [31:0] slave_count, // Slave counter value
    output wire        synced       // Synchronization complete indicator
);

    //-----------------------------------------------------------------------
    // Pipeline Registers for Master Clock Domain
    //-----------------------------------------------------------------------
    reg [31:0] master_count_stage1;
    reg        sync_req_stage1;
    reg        sync_en_stage1;
    reg        sync_match_stage1;
    
    //-----------------------------------------------------------------------
    // Pipeline Registers for Slave Clock Domain
    //-----------------------------------------------------------------------
    reg [31:0] slave_count_stage1;
    reg [31:0] slave_count_stage2;
    reg        sync_pulse_stage1;
    reg        sync_ack_stage1;
    
    // Internal signals for cross-domain synchronization
    reg [2:0]  sync_shift;
    wire       sync_pulse;
    
    // Pipeline valid signals
    reg        master_valid_stage1;
    reg        slave_valid_stage1;
    reg        slave_valid_stage2;

    //-----------------------------------------------------------------------
    // Master Clock Domain Logic - Pipeline Stage 0 to Stage 1
    //-----------------------------------------------------------------------
    
    // First pipeline stage - Register inputs and compute incrementer
    always @(posedge master_clk) begin
        if (reset) begin
            master_count_stage1 <= 32'h0;
            sync_en_stage1 <= 1'b0;
            sync_match_stage1 <= 1'b0;
            master_valid_stage1 <= 1'b0;
        end else begin
            master_count_stage1 <= master_count + 1'b1;
            sync_en_stage1 <= sync_en;
            // Simplified match detection - directly check if low 8 bits are all zero
            sync_match_stage1 <= (master_count[7:0] == 8'h0);
            master_valid_stage1 <= 1'b1;
        end
    end
    
    // Sync request generation - Output of pipeline stage 1
    always @(posedge master_clk) begin
        if (reset) begin
            sync_req_stage1 <= 1'b0;
        end else begin
            // Simplified boolean expression by removing redundant terms
            sync_req_stage1 <= sync_en_stage1 & sync_match_stage1;
        end
    end
    
    // Final master counter output register
    always @(posedge master_clk) begin
        if (reset) begin
            master_count <= 32'h0;
        end else begin
            // Removed conditional check to improve timing
            master_count <= master_count_stage1;
        end
    end

    //-----------------------------------------------------------------------
    // Clock Domain Crossing - Master to Slave - Pipelined
    //-----------------------------------------------------------------------
    
    // Synchronization shift register for clock domain crossing
    always @(posedge slave_clk) begin
        if (reset) begin
            sync_shift <= 3'b0;
        end else begin
            sync_shift <= {sync_shift[1:0], sync_req_stage1};
        end
    end

    // Edge detection for sync pulse - rising edge detection
    assign sync_pulse = sync_shift[1] & ~sync_shift[2];

    //-----------------------------------------------------------------------
    // Slave Clock Domain Logic - Pipeline Stage 0 to Stage 2
    //-----------------------------------------------------------------------
    
    // First pipeline stage - Register sync_pulse and prepare counter update
    always @(posedge slave_clk) begin
        if (reset) begin
            sync_pulse_stage1 <= 1'b0;
            slave_count_stage1 <= 32'h0;
            slave_valid_stage1 <= 1'b0;
        end else begin
            sync_pulse_stage1 <= sync_pulse;
            // Optimized conditional increment
            slave_count_stage1 <= sync_pulse ? 32'h0 : (slave_count + 1'b1);
            slave_valid_stage1 <= 1'b1;
        end
    end
    
    // Second pipeline stage - Process synced signal and update counter
    always @(posedge slave_clk) begin
        if (reset) begin
            sync_ack_stage1 <= 1'b0;
            slave_count_stage2 <= 32'h0;
            slave_valid_stage2 <= 1'b0;
        end else begin
            sync_ack_stage1 <= sync_pulse_stage1;
            slave_count_stage2 <= slave_count_stage1;
            slave_valid_stage2 <= slave_valid_stage1;
        end
    end
    
    // Final output registers
    always @(posedge slave_clk) begin
        if (reset) begin
            slave_count <= 32'h0;
        end else begin
            // Removed conditional check to improve timing
            slave_count <= slave_count_stage2;
        end
    end

    // Output assignment - registered sync acknowledge
    assign synced = sync_ack_stage1;

endmodule