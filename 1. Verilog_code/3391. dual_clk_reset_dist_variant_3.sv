//SystemVerilog
module dual_clk_reset_dist(
    input wire clk_a, clk_b,
    input wire master_rst,
    output reg rst_domain_a, rst_domain_b
);
    // Intermediate registers for improved timing
    reg master_rst_buf_a, master_rst_buf_b;
    
    // Input buffering for domain A
    always @(posedge clk_a) begin
        master_rst_buf_a <= master_rst;
    end
    
    // Input buffering for domain B
    always @(posedge clk_b) begin
        master_rst_buf_b <= master_rst;
    end
    
    // Domain A reset synchronization
    always @(posedge clk_a) begin
        if (master_rst_buf_a) rst_domain_a <= 1'b1;
        else rst_domain_a <= 1'b0;
    end
    
    // Domain B reset synchronization
    always @(posedge clk_b) begin
        if (master_rst_buf_b) rst_domain_b <= 1'b1;
        else rst_domain_b <= 1'b0;
    end
endmodule