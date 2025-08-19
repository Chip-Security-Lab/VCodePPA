module d_latch_out_enable (
    input wire d,
    input wire latch_en,
    input wire out_en,
    output wire q
);
    reg q_internal;
    
    always @* begin
        if (latch_en)
            q_internal = d;
    end
    
    assign q = out_en ? q_internal : 1'bz; // High-Z when output disabled
endmodule