module rising_edge_t_ff (
    input wire clk,
    input wire t,
    output reg q
);
    reg t_prev;
    
    always @(posedge clk) begin
        t_prev <= t;
        if (!t_prev && t) // Rising edge on t
            q <= ~q;
    end
endmodule