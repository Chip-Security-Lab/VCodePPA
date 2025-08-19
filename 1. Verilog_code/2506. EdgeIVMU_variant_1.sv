//SystemVerilog
module EdgeIVMU (
    input clk,
    input rst,
    input [7:0] int_in,
    output reg [31:0] vector,
    output reg valid
);

    // Original: reg [7:0] int_prev; // Holds int_in delayed by 1 cycle
    // Original: assign edge_detect = int_in & ~int_prev;

    // Retiming: Move the register for int_in past the ~ operation.
    // Introduce a register for ~int_in delayed by 1 cycle.
    // This effectively moves the register int_prev forward past the ~ gate.
    reg [7:0] not_int_in_d1; // Holds ~int_in delayed by 1 cycle

    reg [31:0] vector_rom [0:7];
    // wire [7:0] edge_detect; // This signal is still combinational

    integer i;

    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            vector_rom[i] = 32'h5000_0000 + (i * 16);
        end
    end

    // The edge detection logic remains combinational,
    // but now uses the current int_in and the registered ~int_in from the previous cycle.
    // This implements int_in(t) & ~(int_in(t-1)) which is the original edge_detect function.
    wire [7:0] edge_detect_retimed = int_in & not_int_in_d1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Original: int_prev <= 8'h0; // int_in_d1 was reset to 0
            // The new register holds ~int_in_d1. So it should be reset to ~0 = 8'hFF
            not_int_in_d1 <= 8'hFF;

            valid <= 1'b0;
            vector <= 32'h0;
        end else begin
            // Update the new registered signal
            // Original: int_prev <= int_in; // int_in_d1 captures int_in
            // New: not_int_in_d1 captures ~int_in
            not_int_in_d1 <= ~int_in;

            // The rest of the logic uses the retimed edge_detect signal
            valid <= |edge_detect_retimed;

            // Optimized priority logic for vector update
            // This structure ensures only the highest priority match updates vector.
            // Priority is from bit 7 down to bit 0.
            if (edge_detect_retimed[7]) begin
                vector <= vector_rom[7];
            end else if (edge_detect_retimed[6]) begin
                vector <= vector_rom[6];
            end else if (edge_detect_retimed[5]) begin
                vector <= vector_rom[5];
            end else if (edge_detect_retimed[4]) begin
                vector <= vector_rom[4];
            end else if (edge_detect_retimed[3]) begin
                vector <= vector_rom[3];
            end else if (edge_detect_retimed[2]) begin
                vector <= vector_rom[2];
            end else if (edge_detect_retimed[1]) begin
                vector <= vector_rom[1];
            end else if (edge_detect_retimed[0]) begin
                vector <= vector_rom[0];
            end
            // If no edge is detected (|edge_detect_retimed is false),
            // none of the conditions are met, and 'vector' retains its previous value.
        end
    end

endmodule