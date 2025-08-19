module byte_reverser #(
    parameter BYTES = 4  // Default 32-bit word
)(
    input wire clk, rst_n, reverse_en,
    input wire [BYTES*8-1:0] data_in,
    output reg [BYTES*8-1:0] data_out
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {(BYTES*8){1'b0}};
        else if (reverse_en)
            for (i = 0; i < BYTES; i = i + 1)
                data_out[i*8 +: 8] <= data_in[(BYTES-1-i)*8 +: 8];
        else
            data_out <= data_in;
    end
endmodule