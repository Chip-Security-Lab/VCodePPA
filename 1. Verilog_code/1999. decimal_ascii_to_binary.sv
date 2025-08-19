module decimal_ascii_to_binary #(parameter MAX_DIGITS=3)(
    input wire [8*MAX_DIGITS-1:0] ascii_in,
    output reg [$clog2(10**MAX_DIGITS)-1:0] binary_out,
    output reg valid
);
    integer i;
    reg [3:0] digit;
    
    always @* begin
        binary_out = 0;
        valid = 1;
        
        for (i = 0; i < MAX_DIGITS; i = i + 1) begin
            digit = ascii_in[8*i+:8] - 8'h30;
            
            if (digit <= 9) begin
                binary_out = binary_out * 10 + digit;
            end else if (ascii_in[8*i+:8] != 8'h20) begin
                valid = 0;
            end
        end
    end
endmodule