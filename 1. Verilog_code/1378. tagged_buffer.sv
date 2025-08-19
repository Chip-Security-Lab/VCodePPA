module tagged_buffer (
    input wire clk,
    input wire [15:0] data_in,
    input wire [3:0] tag_in,
    input wire write_en,
    output reg [15:0] data_out,
    output reg [3:0] tag_out
);
    always @(posedge clk) begin
        if (write_en) begin
            data_out <= data_in;
            tag_out <= tag_in;
        end
    end
endmodule