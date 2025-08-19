module SatSub(
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] res
);

    // Pipeline stage 1: Input registers
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    
    // Pipeline stage 2: Subtraction computation
    reg [7:0] b_comp_reg;
    reg [7:0] sum_reg;
    reg cout_reg;
    
    // Pipeline stage 3: Saturation logic
    reg [7:0] mask_reg;
    reg [7:0] saturated_diff_reg;

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

    // Stage 2: Subtraction computation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_comp_reg <= 8'h0;
            sum_reg <= 8'h0;
            cout_reg <= 1'b0;
        end else begin
            b_comp_reg <= ~b_reg + 1'b1;
            {cout_reg, sum_reg} <= a_reg + b_comp_reg;
        end
    end

    // Stage 3: Saturation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_reg <= 8'h0;
            saturated_diff_reg <= 8'h0;
        end else begin
            mask_reg <= {8{cout_reg}};
            saturated_diff_reg <= sum_reg & mask_reg;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            res <= 8'h0;
        else
            res <= saturated_diff_reg;
    end

endmodule