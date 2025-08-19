//SystemVerilog
module mult_pipelined (
    input clk,
    input rst_n,
    input req,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg ack,
    output reg [15:0] product
);

    // Pipeline stages
    reg [7:0] multiplicand_stage1, multiplicand_stage2, multiplicand_stage3, multiplicand_stage4;
    reg [7:0] multiplier_stage1, multiplier_stage2, multiplier_stage3, multiplier_stage4;
    reg [15:0] partial_product_stage1, partial_product_stage2, partial_product_stage3, partial_product_stage4;
    reg [2:0] count_stage1, count_stage2, count_stage3, count_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg processing_stage1, processing_stage2, processing_stage3, processing_stage4;
    
    // Stage 1: Input registration and initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_stage1 <= 8'b0;
            multiplier_stage1 <= 8'b0;
            partial_product_stage1 <= 16'b0;
            count_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
            processing_stage1 <= 1'b0;
        end else begin
            if (req && !processing_stage1) begin
                multiplicand_stage1 <= multiplicand;
                multiplier_stage1 <= multiplier;
                partial_product_stage1 <= {8'b0, multiplier};
                count_stage1 <= 3'b0;
                valid_stage1 <= 1'b1;
                processing_stage1 <= 1'b1;
            end else if (valid_stage1) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: First shift and add operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_stage2 <= 8'b0;
            partial_product_stage2 <= 16'b0;
            count_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
            processing_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                multiplicand_stage2 <= multiplicand_stage1;
                partial_product_stage2 <= partial_product_stage1;
                count_stage2 <= count_stage1;
                valid_stage2 <= 1'b1;
                processing_stage2 <= processing_stage1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Second shift and add operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_stage3 <= 8'b0;
            partial_product_stage3 <= 16'b0;
            count_stage3 <= 3'b0;
            valid_stage3 <= 1'b0;
            processing_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                multiplicand_stage3 <= multiplicand_stage2;
                if (partial_product_stage2[0]) 
                    partial_product_stage3 <= {partial_product_stage2[15:8] + multiplicand_stage2, partial_product_stage2[7:1]};
                else
                    partial_product_stage3 <= {1'b0, partial_product_stage2[15:1]};
                count_stage3 <= count_stage2 + 1;
                valid_stage3 <= 1'b1;
                processing_stage3 <= processing_stage2;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // Stage 4: Third shift and add operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_stage4 <= 8'b0;
            partial_product_stage4 <= 16'b0;
            count_stage4 <= 3'b0;
            valid_stage4 <= 1'b0;
            processing_stage4 <= 1'b0;
        end else begin
            if (valid_stage3) begin
                multiplicand_stage4 <= multiplicand_stage3;
                if (partial_product_stage3[0]) 
                    partial_product_stage4 <= {partial_product_stage3[15:8] + multiplicand_stage3, partial_product_stage3[7:1]};
                else
                    partial_product_stage4 <= {1'b0, partial_product_stage3[15:1]};
                count_stage4 <= count_stage3 + 1;
                valid_stage4 <= 1'b1;
                processing_stage4 <= processing_stage3;
            end else begin
                valid_stage4 <= 1'b0;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
            ack <= 1'b0;
        end else begin
            if (valid_stage4) begin
                if (count_stage4 == 3'd7) begin
                    product <= partial_product_stage4;
                    ack <= 1'b1;
                end else begin
                    ack <= 1'b0;
                end
            end else begin
                ack <= 1'b0;
            end
        end
    end
    
endmodule