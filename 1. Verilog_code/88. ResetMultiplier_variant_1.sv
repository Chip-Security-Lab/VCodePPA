//SystemVerilog
module ResetMultiplier(
    input clk, rst,
    input [3:0] x, y,
    output reg [7:0] out
);

    // Pipeline stage signals
    reg [3:0] x_reg, y_reg;
    wire [7:0] product_stage1;
    reg [7:0] product_stage2;

    // Input stage
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x_reg <= 4'b0;
            y_reg <= 4'b0;
        end else begin
            x_reg <= x;
            y_reg <= y;
        end
    end

    // Multiplier core with pipelined inputs
    MultiplierCore multiplier_inst (
        .x(x_reg),
        .y(y_reg),
        .product(product_stage1)
    );

    // Output stage - retimed to reduce critical path
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            product_stage2 <= 8'b0;
        end else begin
            product_stage2 <= product_stage1;
        end
    end
    
    // Separate output register to improve timing
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            out <= 8'b0;
        end else begin
            out <= product_stage2;
        end
    end

endmodule

module MultiplierCore(
    input [3:0] x, y,
    output [7:0] product
);

    // Booth multiplier implementation
    wire [7:0] partial_products [3:0];
    wire [7:0] sum_stage1, sum_stage2;
    reg [7:0] sum_stage1_reg, sum_stage2_reg;
    reg [7:0] product_reg;

    // Generate partial products
    genvar i;
    generate
        for(i=0; i<4; i=i+1) begin: pp_gen
            assign partial_products[i] = y[i] ? (x << i) : 8'b0;
        end
    endgenerate

    // Wallace tree reduction with retimed registers
    always @(*) begin
        sum_stage1_reg = partial_products[0] + partial_products[1];
        sum_stage2_reg = partial_products[2] + partial_products[3];
        product_reg = sum_stage1_reg + sum_stage2_reg;
    end
    
    // Output assignment
    assign product = product_reg;

endmodule