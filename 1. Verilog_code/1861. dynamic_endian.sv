module dynamic_endian #(parameter WIDTH=32) (
    input [WIDTH-1:0] data_in,
    input reverse_en,
    output reg [WIDTH-1:0] data_out
);
    integer i;
    
    always @(*) begin
        if (reverse_en) begin
            for(i=0; i<WIDTH; i=i+1)
                data_out[i] = data_in[WIDTH-1-i];
        end else begin
            data_out = data_in;
        end
    end
endmodule