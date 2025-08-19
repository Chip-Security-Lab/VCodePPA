module d_latch_sync_preset (
    input wire d,
    input wire enable,
    input wire preset,   // Synchronous preset
    output reg q
);
    always @* begin
        if (enable) begin
            if (preset)
                q = 1'b1;
            else
                q = d;
        end
    end
endmodule