module priority_parity_checker (
    input [15:0] data,
    output reg [3:0] parity,
    output reg error
);
wire [7:0] low_byte = data[7:0];
wire [7:0] high_byte = data[15:8];
wire byte_parity = ^low_byte ^ high_byte;

always @(*) begin
    parity = 4'h0;
    error = 1'b0;
    if (byte_parity) begin
        if (low_byte != 0) begin
            parity = low_byte & -low_byte;
            error = 1'b1;
        end
    end
end
endmodule