//SystemVerilog
module freq_div_square(
    input wire master_clk,
    input wire rst_b,
    input wire [15:0] div_factor,
    output reg clk_out
);
    reg [15:0] div_count;
    wire [15:0] div_factor_m1;
    wire count_match;
    
    assign div_factor_m1 = div_factor - 1'b1;
    assign count_match = (div_count == div_factor_m1);
    
    always @(posedge master_clk or negedge rst_b) begin
        if (!rst_b) begin
            div_count <= 16'h0000;
            clk_out <= 1'b0;
        end else begin
            div_count <= count_match ? 16'h0000 : div_count + 1'b1;
            clk_out <= count_match ? ~clk_out : clk_out;
        end
    end
endmodule