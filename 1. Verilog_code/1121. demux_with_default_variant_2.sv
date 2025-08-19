//SystemVerilog
module demux_with_default (
    input wire data_in,                  // Input data
    input wire [2:0] sel_addr,           // Selection address
    output reg [6:0] outputs,            // Normal outputs
    output reg default_out               // Default output for invalid addresses
);

// Optimized combinational logic for outputs and default_out
always @(*) begin : outputs_and_default_assignment
    outputs = 7'b0;
    default_out = 1'b0;
    if (sel_addr < 3'd7) begin
        outputs = 7'b1 << sel_addr;
        outputs = outputs & {7{data_in}};
    end else begin
        default_out = data_in;
    end
end

endmodule