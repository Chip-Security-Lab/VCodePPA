module bin_to_johnson #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] bin_in,
    output reg [2*WIDTH-1:0] johnson_out
);
    integer i;
    reg [WIDTH-1:0] pos;
    
    always @(*) begin
        pos = bin_in % (2*WIDTH);
        johnson_out = 0;
        
        for (i = 0; i < 2*WIDTH; i = i + 1) begin
            if (i < pos)
                johnson_out[i] = 1'b1;
            else
                johnson_out[i] = 1'b0;
        end
        
        if (pos > WIDTH) begin
            johnson_out = ~johnson_out;
        end
    end
endmodule