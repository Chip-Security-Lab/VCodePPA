//SystemVerilog
module multiplier_distributed (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] product,
    output reg product_valid
);

    // Stage 1: Partial product generation
    reg [7:0] partial_product_stage1 [3:0];
    reg valid_stage1;
    
    // Stage 2: First level addition
    reg [7:0] sum_stage2_0;
    reg [7:0] sum_stage2_1;
    reg valid_stage2;
    
    // Stage 3: Final addition
    reg [7:0] product_stage3;
    reg valid_stage3;

    // Stage 1: Partial product generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            for (int i = 0; i < 4; i++) begin
                partial_product_stage1[i] <= 8'b0;
            end
        end else begin
            valid_stage1 <= valid;
            if (valid) begin
                partial_product_stage1[0] <= a[0] ? b : 0;
                partial_product_stage1[1] <= a[1] ? (b << 1) : 0;
                partial_product_stage1[2] <= a[2] ? (b << 2) : 0;
                partial_product_stage1[3] <= a[3] ? (b << 3) : 0;
            end
        end
    end

    // Stage 2: First level addition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            sum_stage2_0 <= 8'b0;
            sum_stage2_1 <= 8'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                sum_stage2_0 <= partial_product_stage1[0] + partial_product_stage1[1];
                sum_stage2_1 <= partial_product_stage1[2] + partial_product_stage1[3];
            end
        end
    end

    // Stage 3: Final addition and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            product_stage3 <= 8'b0;
            product <= 8'b0;
            product_valid <= 1'b0;
            ready <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            ready <= 1'b1;
            
            if (valid_stage2) begin
                product_stage3 <= sum_stage2_0 + sum_stage2_1;
                product <= product_stage3;
                product_valid <= 1'b1;
            end else begin
                product_valid <= 1'b0;
            end
        end
    end

endmodule