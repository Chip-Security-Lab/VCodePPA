//SystemVerilog
module demux_with_default (
    input wire        data_in,           // Input data
    input wire [2:0]  sel_addr,          // Selection address
    output reg [6:0]  outputs,           // Normal outputs
    output reg        default_out        // Default output for invalid addresses
);

    // Combinational logic for outputs based on valid selection address
    // Handles the assignment to the outputs bus when sel_addr is valid (0-6)
    always @(*) begin : outputs_logic
        if (sel_addr < 3'd7) begin
            outputs = data_in << sel_addr;
        end else begin
            outputs = 7'b0;
        end
    end

    // Combinational logic for default output based on invalid selection address
    // Handles the assignment to default_out when sel_addr is invalid (>=7)
    always @(*) begin : default_out_logic
        if (sel_addr < 3'd7) begin
            default_out = 1'b0;
        end else begin
            default_out = data_in;
        end
    end

endmodule