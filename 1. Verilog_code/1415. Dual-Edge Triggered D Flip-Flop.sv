module dual_edge_d_ff (
    input wire clk,
    input wire d,
    output reg q
);
    reg q1, q2;
    
    always @(posedge clk) begin
        q1 <= d;
    end
    
    always @(negedge clk) begin
        q2 <= d;
    end
    
    always @(q1 or q2) begin
        q <= clk ? q1 : q2;
    end
endmodule