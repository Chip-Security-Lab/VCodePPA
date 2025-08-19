module bcd_to_binary #(parameter DIGITS=3)(
    input wire [4*DIGITS-1:0] bcd_in,
    output reg [DIGITS*3+3:0] binary_out
);
    integer i, j;
    reg [DIGITS*3+3:0] temp;
    
    always @* begin
        temp = 0;
        for (i = 0; i < DIGITS; i = i + 1) begin
            temp = temp * 10 + bcd_in[4*i+3 -: 4];
        end
        binary_out = temp;
    end
endmodule