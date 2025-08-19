module neg_edge_siso #(parameter DEPTH = 4) (
    input wire clk_n, arst_n, sin,
    output wire sout
);
    reg [DEPTH-1:0] sr_array;
    
    always @(negedge clk_n or negedge arst_n) begin
        if (!arst_n)
            sr_array <= 0;
        else
            sr_array <= {sr_array[DEPTH-2:0], sin};
    end
    
    assign sout = sr_array[DEPTH-1];
endmodule