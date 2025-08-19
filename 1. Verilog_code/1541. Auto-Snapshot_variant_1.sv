//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: auto_snapshot_shadow_reg.v
// Description: Automatic snapshot register with optimized data flow structure
//              and pipelined control logic for improved timing
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////
module auto_snapshot_shadow_reg #(
    parameter WIDTH = 16
)(
    input  wire             clk,            // System clock
    input  wire             rst_n,          // Active-low reset
    input  wire [WIDTH-1:0] data_in,        // Input data to be monitored
    input  wire             error_detected, // Error detection signal
    output reg  [WIDTH-1:0] shadow_data,    // Snapshot data when error occurs
    output reg              snapshot_taken  // Indicates a snapshot has been captured
);

    // -------------------------------------------------------------------------
    // Stage 1: Input Data Capture Pipeline
    // -------------------------------------------------------------------------
    reg [WIDTH-1:0] data_in_reg;  // Input data pipeline register
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_in_reg <= {WIDTH{1'b0}};
        else
            data_in_reg <= data_in;
    end
    
    // -------------------------------------------------------------------------
    // Stage 2: Main Data Register Pipeline with additional stage for timing
    // -------------------------------------------------------------------------
    reg [WIDTH-1:0] main_reg_stage1;  // First stage of main data pipeline
    reg [WIDTH-1:0] main_reg;         // Final main data pipeline register
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage1 <= {WIDTH{1'b0}};
            main_reg <= {WIDTH{1'b0}};
        end else begin
            main_reg_stage1 <= data_in_reg;
            main_reg <= main_reg_stage1;
        end
    end
    
    // -------------------------------------------------------------------------
    // Stage 3: Error Detection Pipeline with multi-stage processing
    // -------------------------------------------------------------------------
    reg error_detected_reg1;      // First error detection pipeline register
    reg error_detected_reg2;      // Second error detection pipeline register
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_detected_reg1 <= 1'b0;
            error_detected_reg2 <= 1'b0;
        end else begin
            error_detected_reg1 <= error_detected;
            error_detected_reg2 <= error_detected_reg1;
        end
    end
    
    // -------------------------------------------------------------------------
    // Stage 4: Snapshot Control Logic with optimized pipelined decision path
    // -------------------------------------------------------------------------
    reg snapshot_pending;         // Snapshot pending indicator
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snapshot_pending <= 1'b0;
        end else begin
            if (error_detected_reg2 && !snapshot_taken)
                snapshot_pending <= 1'b1;
            else if (snapshot_taken)
                snapshot_pending <= 1'b0;
        end
    end
    
    // -------------------------------------------------------------------------
    // Stage 5: Shadow Data Capture and Status Control
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            snapshot_taken <= 1'b0;
        end else begin
            if (snapshot_pending && !snapshot_taken) begin
                shadow_data <= main_reg;
                snapshot_taken <= 1'b1;
            end else if (!error_detected_reg2 && snapshot_taken) begin
                snapshot_taken <= 1'b0;
            end
        end
    end

endmodule