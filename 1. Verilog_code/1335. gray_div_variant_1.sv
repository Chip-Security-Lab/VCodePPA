//SystemVerilog
module gray_div #(parameter WIDTH=4) (
    input wire clk, rst,
    output reg clk_div
);
    reg [WIDTH-1:0] gray_cnt;
    wire [WIDTH-1:0] next_gray;
    reg toggle_clk_div_reg;
    
    // Binary to Gray code conversion for next state
    assign next_gray = (gray_cnt + 1'b1) ^ ((gray_cnt + 1'b1) >> 1);
    
    // Detect the maximum binary value condition more efficiently
    // Using property that all 1's in binary has a specific gray code pattern
    // Register the detection logic to reduce critical path
    wire toggle_clk_div = (gray_cnt == {1'b1, {(WIDTH-1){1'b0}}});
    
    // Gray counter update logic
    always @(posedge clk) begin
        if(rst) begin
            gray_cnt <= {WIDTH{1'b0}};
            toggle_clk_div_reg <= 1'b0;
        end
        else begin
            gray_cnt <= next_gray;
            toggle_clk_div_reg <= toggle_clk_div;
        end
    end
    
    // Clock divider output logic - moved the register backward through the detection logic
    always @(posedge clk) begin
        if(rst) begin
            clk_div <= 1'b0;
        end
        else begin
            clk_div <= toggle_clk_div_reg;
        end
    end
endmodule