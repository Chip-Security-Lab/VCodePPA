module priority_buffer (
    input wire clk,
    input wire [7:0] data_a, data_b, data_c,
    input wire valid_a, valid_b, valid_c,
    output reg [7:0] data_out,
    output reg [1:0] source
);
    always @(posedge clk) begin
        if (valid_a) begin
            data_out <= data_a;
            source <= 2'b00;
        end else if (valid_b) begin
            data_out <= data_b;
            source <= 2'b01;
        end else if (valid_c) begin
            data_out <= data_c;
            source <= 2'b10;
        end
    end
endmodule