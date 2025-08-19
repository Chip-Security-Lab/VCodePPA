//SystemVerilog
// SystemVerilog

// Reusable module to detect an error condition at a specific trigger event
module error_detector_at_trigger (
    input clk,
    input rst_n,
    input trigger,     // Pulse or signal indicating the event
    input condition,   // Condition to check when trigger is high
    output reg error_out // Registered output: 1 if condition met at trigger, 0 otherwise
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_out <= 1'b0;
        end else begin
            if (trigger) begin
                error_out <= condition;
            end else begin
                error_out <= 1'b0; // Reset when not triggered
            end
        end
    end

endmodule


// Top module implementing CAN Error Detection using reusable submodules
// Transformed to use Valid-Ready handshake for error output
module CAN_Monitor_Error_Detect #(
    parameter DATA_WIDTH = 8 // Parameter from original code, kept for compatibility
)(
    input clk,
    input rst_n,
    input can_rx,
    input can_tx,

    // Valid-Ready handshake interface for error flags output
    output logic [2:0] error_flags_out, // Bundled errors: {form_error, ack_error, crc_error}
    output logic error_flags_valid,
    input logic error_flags_ready
);
    // Internal state
    reg [6:0] bit_counter;
    reg [14:0] crc_calc;
    reg [14:0] crc_received;
    reg form_error_reg; // form_error is now internal

    // Wires for trigger conditions based on bit_counter
    wire counter_eq_96;
    wire counter_eq_97;

    // Wires for conditions fed to submodules
    wire ack_condition;
    wire crc_condition;

    // Outputs from submodules (kept as internal wires)
    wire ack_error_out_sub;
    wire crc_error_out_sub;

    // Internal registers for Valid-Ready handshake logic
    reg counter_eq_96_dly; // Delayed trigger for ack_error_out_sub stabilization
    reg counter_eq_97_dly; // Delayed trigger for crc_error_out_sub stabilization
    wire new_error_data_ready = counter_eq_96_dly || counter_eq_97_dly; // Indicates when error outputs from subs are stable

    reg [2:0] error_flags_reg; // Register to hold output data
    reg error_flags_valid_reg; // Register for the valid signal

    // Main state update logic (counter, CRC) and form_error
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 7'd0;
            crc_calc <= 15'd0;
            crc_received <= 15'd0;
            form_error_reg <= 1'b0; // Reset form_error
        end else begin
            // Increment counter
            bit_counter <= bit_counter + 7'd1;

            // CRC calculation (as in original code)
            // Note: This CRC is calculated continuously, not just per bit.
            // The original code's CRC logic seems simplified/example-like.
            // Keeping the original logic structure.
            crc_calc <= {crc_calc[13:0], 1'b0} ^
                       ((crc_calc[14] ^ can_rx) ? 15'h4599 : 15'h0);

            // Update crc_received conditionally based on counter value 95
            // Assuming can_rx at bit_counter == 95 is the last bit of CRC field
            if (bit_counter == 7'd95) begin
                crc_received <= {crc_received[13:0], can_rx};
            end
            // crc_received retains its value otherwise

            // Form error detection (as in original code - registered logic)
            // This logic is different from timed errors and remains here
            form_error_reg <= (can_rx && can_tx);
        end
    end

    // Generate trigger signals for specific counter values
    assign counter_eq_96 = (bit_counter == 7'd96);
    assign counter_eq_97 = (bit_counter == 7'd97);

    // Delay trigger signals by one cycle to align with registered submodule outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_eq_96_dly <= 1'b0;
            counter_eq_97_dly <= 1'b0;
        end else begin
            counter_eq_96_dly <= counter_eq_96;
            counter_eq_97_dly <= counter_eq_97;
        end
    end


    // Generate condition signals for error checks
    assign ack_condition = !can_tx; // Check if can_tx is low at trigger
    assign crc_condition = (crc_calc != crc_received); // Check if calculated CRC matches received CRC at trigger

    // Instantiate reusable error detection submodules
    error_detector_at_trigger ack_detector (
        .clk(clk),
        .rst_n(rst_n),
        .trigger(counter_eq_96),        // Trigger at counter value 96
        .condition(ack_condition),      // Check if can_tx is low
        .error_out(ack_error_out_sub)   // Registered output
    );

    error_detector_at_trigger crc_detector (
        .clk(clk),
        .rst_n(rst_n),
        .trigger(counter_eq_97),        // Trigger at counter value 97
        .condition(crc_condition),      // Check if calculated CRC matches received CRC
        .error_out(crc_error_out_sub)   // Registered output
    );

    // Valid-Ready handshake logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_flags_reg <= 3'b0;
            error_flags_valid_reg <= 1'b0;
        end else begin
            if (error_flags_valid_reg && error_flags_ready) begin
                // Data consumed by receiver, deassert valid
                error_flags_valid_reg <= 1'b0;
                // Data register holds value until next data is loaded
            end else if (!error_flags_valid_reg && new_error_data_ready) begin
                // New data is ready (one cycle after trigger) and output is not currently valid
                // Capture the error flags: {form_error_reg, ack_error_out_sub, crc_error_out_sub}
                // At counter_eq_96_dly, ack_error_out_sub is the new value, crc_error_out_sub is the old one.
                // At counter_eq_97_dly, crc_error_out_sub is the new value, ack_error_out_sub is the value from counter_eq_96_dly event.
                // form_error_reg is the current value.
                error_flags_reg <= {form_error_reg, ack_error_out_sub, crc_error_out_sub}; // Capture data
                error_flags_valid_reg <= 1'b1; // Assert valid
            end
            // If error_flags_valid_reg is high and error_flags_ready is low,
            // the registers retain their value, holding the data and valid signal.
            // If error_flags_valid_reg is low and new_error_data_ready is low,
            // the registers retain their value, keeping valid low.
        end
    end

    // Assign output ports from internal registers
    assign error_flags_out = error_flags_reg;
    assign error_flags_valid = error_flags_valid_reg;

endmodule