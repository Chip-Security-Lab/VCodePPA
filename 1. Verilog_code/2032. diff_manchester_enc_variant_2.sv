//SystemVerilog
module diff_manchester_enc (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  encoded
);
    reg prev_bit;

    always @(posedge clk or negedge rst_n) begin
        encoded  <= (!rst_n) ? 1'b0 : (prev_bit ^ data_in);
        prev_bit <= (!rst_n) ? 1'b0 : (prev_bit ^ data_in);
    end
endmodule