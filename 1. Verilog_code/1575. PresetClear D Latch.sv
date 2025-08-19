module d_latch_preset_clear (
    input wire d,
    input wire enable,
    input wire preset_n, // Active low preset
    input wire clear_n,  // Active low clear
    output reg q
);
    always @* begin
        if (!clear_n)
            q = 1'b0;
        else if (!preset_n)
            q = 1'b1;
        else if (enable)
            q = d;
    end
endmodule