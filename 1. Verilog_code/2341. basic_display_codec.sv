module basic_display_codec (
    input clk, rst_n,
    input [7:0] pixel_in,
    output reg [15:0] display_out
);
    always @(posedge clk) begin
        if (!rst_n)
            display_out <= 16'h0000;
        else
            display_out <= {pixel_in[7:5], 5'b0, pixel_in[4:2], 5'b0, pixel_in[1:0], 6'b0};
    end
endmodule