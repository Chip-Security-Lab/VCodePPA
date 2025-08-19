//SystemVerilog
module rising_edge_t_ff (
    input wire clk,
    input wire t,
    output reg q
);
    reg t_delayed;
    reg edge_detected;
    reg t_rising;
    
    always @(posedge clk) begin
        t_delayed <= t;
        t_rising <= !t_delayed && t;
    end
    
    always @(posedge clk) begin
        if (t_rising)
            q <= ~q;
    end
endmodule