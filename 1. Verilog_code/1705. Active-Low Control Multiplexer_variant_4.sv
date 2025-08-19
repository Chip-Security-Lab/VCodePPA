//SystemVerilog
module active_low_mux(
    input [23:0] src_a, src_b,
    input sel_n, en_n,
    output reg [23:0] dest
);

    always @(*) begin
        if (!en_n && !sel_n) begin
            dest = src_a;
        end
        else if (!en_n && sel_n) begin
            dest = src_b;
        end
        else begin
            dest = 24'h0;
        end
    end

endmodule