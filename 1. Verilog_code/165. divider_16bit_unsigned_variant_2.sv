//SystemVerilog
module divider_16bit_unsigned (
    input [15:0] a,
    input [15:0] b,
    output [15:0] quotient,
    output [15:0] remainder
);

    reg [15:0] q;
    reg [15:0] r;
    reg [15:0] d;
    reg [4:0] count;
    reg start;
    reg done;

    always @(*) begin
        if (b == 0) begin
            q = 16'hFFFF;
            r = 16'hFFFF;
        end else begin
            q = 0;
            r = a;
            d = b;
            
            for (count = 0; count < 16; count = count + 1) begin
                if (r >= d) begin
                    r = r - d;
                    q = (q << 1) | 1'b1;
                end else begin
                    q = q << 1;
                end
                d = d >> 1;
            end
        end
    end

    assign quotient = q;
    assign remainder = r;

endmodule