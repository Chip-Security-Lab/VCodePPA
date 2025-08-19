//SystemVerilog
module dual_edge_d_ff (
    input wire clk,
    input wire d,
    output reg q
);
    reg pos_data, neg_data;
    
    always @(posedge clk) begin
        pos_data <= d;
    end
    
    always @(negedge clk) begin
        neg_data <= d;
    end
    
    always @(*) begin
        q = clk ? pos_data : neg_data;
    end
endmodule