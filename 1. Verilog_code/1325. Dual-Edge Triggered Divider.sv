module dual_edge_divider (
    input clkin, rst,
    output reg clkout
);
    reg [1:0] pos_count, neg_count;
    reg pos_toggle, neg_toggle;
    
    always @(posedge clkin or posedge rst) begin
        if (rst) begin
            pos_count <= 2'b00;
            pos_toggle <= 1'b0;
        end else if (pos_count == 2'b11) begin
            pos_count <= 2'b00;
            pos_toggle <= ~pos_toggle;
        end else
            pos_count <= pos_count + 1'b1;
    end
    
    always @(negedge clkin or posedge rst) begin
        if (rst) begin
            neg_count <= 2'b00;
            neg_toggle <= 1'b0;
        end else if (neg_count == 2'b11) begin
            neg_count <= 2'b00;
            neg_toggle <= ~neg_toggle;
        end else
            neg_count <= neg_count + 1'b1;
    end
    
    always @(pos_toggle or neg_toggle)
        clkout = pos_toggle ^ neg_toggle;
endmodule