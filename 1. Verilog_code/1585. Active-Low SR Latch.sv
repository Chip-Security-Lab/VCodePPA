module sr_latch_active_low (
    input wire s_n,      // Active-low set
    input wire r_n,      // Active-low reset
    output reg q,
    output wire q_bar
);
    assign q_bar = ~q;
    
    always @* begin
        if (!s_n && r_n)
            q = 1'b1;
        else if (s_n && !r_n)
            q = 1'b0;
        // Hold state when s_n=1, r_n=1
        // Metastable when s_n=0, r_n=0
    end
endmodule