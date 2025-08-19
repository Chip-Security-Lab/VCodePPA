//SystemVerilog
module counter_divider #(parameter RATIO=10) (
    input clk, rst,
    output reg clk_out
);
    localparam WIDTH = $clog2(RATIO);
    
    reg [WIDTH-1:0] cnt;
    wire [WIDTH-1:0] next_cnt;
    reg [WIDTH-1:0] ratio_minus_one_reg;
    wire cnt_reached_limit;
    
    // Register ratio_minus_one to reduce fanout
    always @(posedge clk) begin
        ratio_minus_one_reg <= RATIO - 1;
    end
    
    // Compute next counter value
    assign next_cnt = (cnt == ratio_minus_one_reg) ? {WIDTH{1'b0}} : 
                      ((~(ratio_minus_one_reg - cnt)) + 1'b1);
    
    // Determine if counter reached limit
    assign cnt_reached_limit = (cnt == ratio_minus_one_reg);
    
    // Counter update logic
    always @(posedge clk) begin
        if (rst) begin
            cnt <= {WIDTH{1'b0}};
        end else begin
            cnt <= next_cnt;
        end
    end
    
    // Clock output toggle logic
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else if (cnt_reached_limit) begin
            clk_out <= ~clk_out;
        end
    end
endmodule