// Top-level module
module SatSub(
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] res
);
    // Pipeline registers
    reg [7:0] a_reg, b_reg;
    reg [7:0] a_reg2, b_reg2;
    reg [7:0] diff_reg;
    reg greater_equal_reg;
    
    // Internal signals
    wire [7:0] diff;
    wire greater_equal;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'h0;
            b_reg <= 8'h0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: Comparison and subtraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg2 <= 8'h0;
            b_reg2 <= 8'h0;
            greater_equal_reg <= 1'b0;
        end else begin
            a_reg2 <= a_reg;
            b_reg2 <= b_reg;
            greater_equal_reg <= (a_reg >= b_reg);
        end
    end
    
    // Stage 3: Subtraction result registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_reg <= 8'h0;
        end else begin
            diff_reg <= a_reg2 + (~b_reg2 + 1'b1);
        end
    end
    
    // Stage 4: Output selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 8'h0;
        end else begin
            res <= greater_equal_reg ? diff_reg : 8'h0;
        end
    end
endmodule