module cascaded_clk_divider(
    input clk_in,
    input rst,
    output [3:0] clk_out
);
    reg [3:0] divider;
    
    always @(posedge clk_in or posedge rst) begin
        if (rst)
            divider <= 4'b0000;
        else
            divider[0] <= ~divider[0];
    end
    
    always @(posedge divider[0] or posedge rst) begin
        if (rst)
            divider[1] <= 1'b0;
        else
            divider[1] <= ~divider[1];
    end
    
    always @(posedge divider[1] or posedge rst) begin
        if (rst)
            divider[2] <= 1'b0;
        else
            divider[2] <= ~divider[2];
    end
    
    always @(posedge divider[2] or posedge rst) begin
        if (rst)
            divider[3] <= 1'b0;
        else
            divider[3] <= ~divider[3];
    end
    
    assign clk_out = divider;
endmodule