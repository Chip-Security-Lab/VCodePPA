module gray_converter #(parameter WIDTH=4) (
    input [WIDTH-1:0] bin_in,
    input bin_to_gray,
    output reg [WIDTH-1:0] result
);
    integer i;
    
    always @(*) begin
        if (bin_to_gray)
            result = bin_in ^ (bin_in >> 1);
        else begin
            result[WIDTH-1] = bin_in[WIDTH-1];
            for(i=WIDTH-2; i>=0; i=i-1)
                result[i] = bin_in[i] ^ result[i+1];
        end
    end
endmodule