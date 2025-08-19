module dual_clk_reset_dist(
    input wire clk_a, clk_b,
    input wire master_rst,
    output reg rst_domain_a, rst_domain_b
);
    // Domain A reset synchronization
    always @(posedge clk_a or posedge master_rst)
        if (master_rst) rst_domain_a <= 1'b1;
        else rst_domain_a <= 1'b0;
    
    // Domain B reset synchronization
    always @(posedge clk_b or posedge master_rst)
        if (master_rst) rst_domain_b <= 1'b1;
        else rst_domain_b <= 1'b0;
endmodule