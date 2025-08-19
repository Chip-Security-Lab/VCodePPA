module subtractor_16bit (
    input wire clk,
    input wire rst_n,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] diff
);

    // Pipeline stage 1: Input registers
    reg [15:0] a_reg;
    reg [15:0] b_reg;
    
    // Pipeline stage 2: Subtraction computation with carry lookahead
    wire [15:0] diff_wire;
    wire [15:0] b_comp;
    wire [15:0] sum;
    wire carry_out;
    
    // Two's complement of b
    assign b_comp = ~b_reg + 1'b1;
    
    // Carry lookahead addition
    assign {carry_out, sum} = a_reg + b_comp;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'b0;
            b_reg <= 16'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: Subtraction computation
    assign diff_wire = sum;
    
    // Stage 3: Output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff <= 16'b0;
        end else begin
            diff <= diff_wire;
        end
    end

endmodule