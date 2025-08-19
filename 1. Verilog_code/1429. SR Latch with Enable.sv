module sr_latch_enable (
    input wire enable,
    input wire s,
    input wire r,
    output reg q
);
    always @(*) begin
        if (enable) begin
            if (s && !r)
                q <= 1'b1;
            else if (!s && r)
                q <= 1'b0;
        end
    end
endmodule