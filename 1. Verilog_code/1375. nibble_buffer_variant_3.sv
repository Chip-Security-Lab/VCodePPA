//SystemVerilog
module nibble_buffer (
    input wire clk,
    input wire [3:0] nibble_in,
    input wire upper_en, lower_en,
    output reg [7:0] byte_out
);
    // Directly use input signals for output logic
    // This eliminates the input registers and moves them forward
    always @(posedge clk) begin
        if (upper_en)
            byte_out[7:4] <= nibble_in;
        if (lower_en)
            byte_out[3:0] <= nibble_in;
    end
endmodule