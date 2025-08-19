module d_latch_sync_rst (
    input wire d,
    input wire enable,
    input wire rst,      // Active high reset
    output reg q
);
    always @* begin
        if (enable) begin
            if (rst)
                q = 1'b0;
            else
                q = d;
        end
    end
endmodule