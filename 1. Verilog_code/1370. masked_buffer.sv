module masked_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire [15:0] mask,
    input wire write_en,
    output reg [15:0] data_out
);
    always @(posedge clk) begin
        if (write_en)
            data_out <= (data_in & mask) | (data_out & ~mask);
    end
endmodule