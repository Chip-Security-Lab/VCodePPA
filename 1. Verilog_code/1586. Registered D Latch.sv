module d_latch_registered (
    input wire d,
    input wire latch_enable,
    input wire clk,
    output reg q_reg
);
    reg q_internal;
    
    always @* begin
        if (latch_enable)
            q_internal = d;
    end
    
    always @(posedge clk)
        q_reg <= q_internal;
endmodule