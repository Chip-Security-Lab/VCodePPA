//SystemVerilog
// Top level module
module clk_gate_mask #(
    parameter MASK = 4'b1100
)(
    input  wire       clk,
    input  wire       en,
    output wire [3:0] out
);
    wire [3:0] current_out;
    wire [3:0] next_out;
    
    // Instance of mask logic module
    mask_logic #(
        .MASK(MASK)
    ) mask_logic_inst (
        .current_value(current_out),
        .enable(en),
        .masked_value(next_out)
    );
    
    // Instance of output register module
    output_register output_register_inst (
        .clk(clk),
        .next_value(next_out),
        .current_value(current_out)
    );
    
    // Connect the output
    assign out = current_out;
    
endmodule

// Mask logic module
module mask_logic #(
    parameter MASK = 4'b1100
)(
    input  wire [3:0] current_value,
    input  wire       enable,
    output wire [3:0] masked_value
);
    assign masked_value = enable ? (current_value | MASK) : current_value;
endmodule

// Output register module
module output_register (
    input  wire       clk,
    input  wire [3:0] next_value,
    output reg  [3:0] current_value
);
    always @(posedge clk) begin
        current_value <= next_value;
    end
endmodule