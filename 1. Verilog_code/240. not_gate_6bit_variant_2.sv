//SystemVerilog
// SystemVerilog
// 6-bit NOT gate top module with registered output
module not_gate_6bit (
    input wire clk,
    input wire rst_n,
    input wire [5:0] data_in,
    output reg [5:0] data_out
);

    // Internal wire for the combinational NOT operation output
    wire [5:0] data_inverted;

    // Instantiate 6 individual NOT gate sub-modules
    not_gate_1bit not_inst_0 (.in(data_in[0]), .out(data_inverted[0]));
    not_gate_1bit not_inst_1 (.in(data_in[1]), .out(data_inverted[1]));
    not_gate_1bit not_inst_2 (.in(data_in[2]), .out(data_inverted[2]));
    not_gate_1bit not_inst_3 (.in(data_in[3]), .out(data_inverted[3]));
    not_gate_1bit not_inst_4 (.in(data_in[4]), .out(data_inverted[4]));
    not_gate_1bit not_inst_5 (.in(data_in[5]), .out(data_inverted[5]));

    // Register the output for improved timing and a clear pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 6'b0; // Reset to a known state
        end else begin
            data_out <= data_inverted;
        end
    end

endmodule

// 1-bit NOT gate sub-module
module not_gate_1bit (
    input wire in,
    output wire out
);

    assign out = ~in;

endmodule