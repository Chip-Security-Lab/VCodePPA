module counter_dual_edge #(parameter WIDTH=4) (
    input clk, rst,
    output [WIDTH-1:0] cnt
);
    reg [WIDTH-1:0] pos_cnt;
    reg [WIDTH-1:0] neg_cnt;
    
    // Posedge counter
    always @(posedge clk or posedge rst) begin
        if (rst) pos_cnt <= 0;
        else pos_cnt <= pos_cnt + 1;
    end
    
    // Negedge counter
    always @(negedge clk or posedge rst) begin
        if (rst) neg_cnt <= 0;
        else neg_cnt <= neg_cnt + 1;
    end
    
    // Total count
    assign cnt = pos_cnt + neg_cnt;
endmodule