//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: priority_recovery_top.v
// Description: Priority recovery system with hierarchical modular design
///////////////////////////////////////////////////////////////////////////////
module priority_recovery_top (
    input  wire       clk,
    input  wire       rst_n,         // Added reset signal for proper initialization
    input  wire       enable,
    input  wire [7:0] signals,
    input  wire       ready,         // Added ready signal for handshake
    output wire [2:0] recovered_idx,
    output wire       valid
);
    // Internal signals
    wire [2:0] detected_index;
    wire       signal_present;
    wire       internal_valid;
    wire       internal_ready;

    // Handshake control signals
    assign internal_ready = ready | ~valid; // Ready for new data when downstream is ready or when not valid

    // Instantiate signal detector module
    signal_detector u_signal_detector (
        .signals        (signals),
        .signal_present (signal_present),
        .detected_index (detected_index)
    );

    // Instantiate output controller module with handshake interface
    output_controller u_output_controller (
        .clk           (clk),
        .rst_n         (rst_n),
        .enable        (enable),
        .signal_present(signal_present),
        .detected_index(detected_index),
        .internal_ready(internal_ready),
        .recovered_idx (recovered_idx),
        .valid         (valid)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: signal_detector.v
// Description: Detects highest priority signal and its index
///////////////////////////////////////////////////////////////////////////////
module signal_detector (
    input  wire [7:0] signals,
    output wire       signal_present,
    output reg  [2:0] detected_index
);
    // Determine if any signal is present
    assign signal_present = |signals;

    // Priority encoder logic (combinational)
    always @(*) begin
        casez (signals)
            8'b1???????: detected_index = 3'd7;
            8'b01??????: detected_index = 3'd6;
            8'b001?????: detected_index = 3'd5;
            8'b0001????: detected_index = 3'd4;
            8'b00001???: detected_index = 3'd3;
            8'b000001??: detected_index = 3'd2;
            8'b0000001?: detected_index = 3'd1;
            8'b00000001: detected_index = 3'd0;
            default:     detected_index = 3'd0;
        endcase
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: output_controller.v
// Description: Controls output signals based on detection results and enable
// Implements Valid-Ready handshake protocol
///////////////////////////////////////////////////////////////////////////////
module output_controller (
    input  wire       clk,
    input  wire       rst_n,         // Added reset for proper initialization
    input  wire       enable,
    input  wire       signal_present,
    input  wire [2:0] detected_index,
    input  wire       internal_ready, // Added ready signal for handshake
    output reg  [2:0] recovered_idx,
    output reg        valid
);
    // Register outputs on clock edge with Valid-Ready handshake
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 1'b0;
            recovered_idx <= 3'b000;
        end else if (enable) begin
            if (internal_ready) begin
                // Only update when ready for new data
                valid <= signal_present;
                if (signal_present) begin
                    recovered_idx <= detected_index;
                end
            end
        end else begin
            // Not enabled
            if (internal_ready) begin
                valid <= 1'b0;
                // recovered_idx maintains its value when not enabled
            end
        end
    end

endmodule