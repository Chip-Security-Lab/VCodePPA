//SystemVerilog
module async_multi_rate_filter #(
    parameter W = 10
)(
    input clk,
    input rst_n,
    input [W-1:0] fast_in,
    input [W-1:0] slow_in,
    input [3:0] alpha,  // Blend factor 0-15
    output reg [W-1:0] filtered_out
);

    // Pipeline stage 1: Input scaling
    reg [W+4-1:0] fast_scaled_r, slow_scaled_r;
    reg [3:0] alpha_r;
    reg [W-1:0] fast_in_r, slow_in_r;
    
    // Pipeline stage 2: Summation
    reg [W+4-1:0] sum_r;
    
    // Pipeline stage 1 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_scaled_r <= 0;
            slow_scaled_r <= 0;
            alpha_r <= 0;
            fast_in_r <= 0;
            slow_in_r <= 0;
        end else begin
            fast_scaled_r <= fast_in * alpha;
            slow_scaled_r <= slow_in * (16 - alpha);
            alpha_r <= alpha;
            fast_in_r <= fast_in;
            slow_in_r <= slow_in;
        end
    end
    
    // Pipeline stage 2 logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_r <= 0;
        end else begin
            sum_r <= fast_scaled_r + slow_scaled_r;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_out <= 0;
        end else begin
            filtered_out <= sum_r >> 4;
        end
    end

endmodule