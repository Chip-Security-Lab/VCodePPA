//SystemVerilog
module multiplier_high_priority (
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] product
);

    // Pipeline stage 1: Input register and booth encoding
    reg [7:0] multiplicand_reg;
    reg [7:0] multiplier_reg;
    reg [1:0] booth_bits_reg;
    reg [3:0] booth_counter_reg;
    
    // Pipeline stage 2: Partial product generation
    reg [8:0] partial_product_reg;
    
    // Pipeline stage 3: Accumulation
    reg [15:0] booth_result_reg;
    
    // Stage 1: Input register and booth encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_reg <= 8'b0;
            multiplier_reg <= 8'b0;
            booth_bits_reg <= 2'b0;
            booth_counter_reg <= 4'b0;
        end else begin
            multiplicand_reg <= a;
            multiplier_reg <= b;
            booth_bits_reg <= {multiplier_reg[0], (booth_counter_reg == 0) ? 1'b0 : multiplier_reg[booth_counter_reg-1]};
            booth_counter_reg <= booth_counter_reg + 1;
        end
    end
    
    // Stage 2: Partial product generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            partial_product_reg <= 9'b0;
        end else begin
            case (booth_bits_reg)
                2'b00: partial_product_reg <= 9'b0;
                2'b01: partial_product_reg <= {1'b0, multiplicand_reg};
                2'b10: partial_product_reg <= {1'b1, ~multiplicand_reg + 1'b1};
                2'b11: partial_product_reg <= 9'b0;
            endcase
        end
    end
    
    // Stage 3: Accumulation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_result_reg <= 16'b0;
            product <= 16'b0;
        end else begin
            if (booth_counter_reg == 0) begin
                booth_result_reg <= 16'b0;
            end else begin
                booth_result_reg <= booth_result_reg + (partial_product_reg << booth_counter_reg);
            end
            product <= booth_result_reg;
        end
    end

endmodule