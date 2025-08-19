module conditional_buffer (
    input wire clk,
    input wire [7:0] data_in,
    input wire [7:0] threshold,
    input wire compare_en,
    output reg [7:0] data_out
);
    always @(posedge clk) begin
        if (compare_en && (data_in > threshold))
            data_out <= data_in;
    end
endmodule