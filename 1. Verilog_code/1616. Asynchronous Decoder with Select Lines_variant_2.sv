//SystemVerilog
module karatsuba_multiplier (
    input clk,
    input rst_n,
    input [3:0] a,
    input [3:0] b,
    output reg [7:0] product
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // Stage 1: Input Splitting
    reg [1:0] a_high, a_low;
    reg [1:0] b_high, b_low;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_high <= 2'b0;
            a_low <= 2'b0;
            b_high <= 2'b0;
            b_low <= 2'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_high <= a[3:2];
            a_low <= a[1:0];
            b_high <= b[3:2];
            b_low <= b[1:0];
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Base Multiplications
    wire [3:0] z0, z2;
    reg [3:0] z0_reg, z2_reg;
    
    multiplier_2bit m0 (.clk(clk), .rst_n(rst_n), .a(a_low), .b(b_low), .product(z0));
    multiplier_2bit m1 (.clk(clk), .rst_n(rst_n), .a(a_high), .b(b_high), .product(z2));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z0_reg <= 4'b0;
            z2_reg <= 4'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            z0_reg <= z0;
            z2_reg <= z2;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Sum Calculations
    reg [3:0] a_sum, b_sum;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_sum <= 4'b0;
            b_sum <= 4'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage1) begin
            a_sum <= {2'b00, a_high} + {2'b00, a_low};
            b_sum <= {2'b00, b_high} + {2'b00, b_low};
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Middle Term Calculation
    wire [3:0] z1_temp;
    reg [3:0] z1;
    
    multiplier_2bit m2 (.clk(clk), .rst_n(rst_n), .a(a_sum[1:0]), .b(b_sum[1:0]), .product(z1_temp));
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z1 <= 4'b0;
            valid_stage4 <= 1'b0;
        end else if (valid_stage2 && valid_stage3) begin
            z1 <= z1_temp - z0_reg - z2_reg;
            valid_stage4 <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end

    // Stage 5: Final Product Assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'b0;
            valid_stage5 <= 1'b0;
        end else if (valid_stage4) begin
            product <= (z2_reg << 4) + (z1 << 2) + z0_reg;
            valid_stage5 <= 1'b1;
        end else begin
            valid_stage5 <= 1'b0;
        end
    end

endmodule

module multiplier_2bit (
    input clk,
    input rst_n,
    input [1:0] a,
    input [1:0] b,
    output reg [3:0] product
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // Stage 1: Input Splitting
    reg a_high, a_low;
    reg b_high, b_low;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_high <= 1'b0;
            a_low <= 1'b0;
            b_high <= 1'b0;
            b_low <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_high <= a[1];
            a_low <= a[0];
            b_high <= b[1];
            b_low <= b[0];
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: Base Multiplications
    reg z0, z2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z0 <= 1'b0;
            z2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            z0 <= a_low & b_low;
            z2 <= a_high & b_high;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Sum Calculations
    reg [1:0] a_sum, b_sum;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_sum <= 2'b0;
            b_sum <= 2'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage1) begin
            a_sum <= a_high + a_low;
            b_sum <= b_high + b_low;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Middle Term Calculation
    reg z1_temp;
    reg z1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z1_temp <= 1'b0;
            valid_stage4 <= 1'b0;
        end else if (valid_stage3) begin
            z1_temp <= a_sum & b_sum;
            valid_stage4 <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z1 <= 1'b0;
        end else if (valid_stage2 && valid_stage4) begin
            z1 <= z1_temp - z0 - z2;
        end
    end

    // Stage 5: Final Product Assembly
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 4'b0;
            valid_stage5 <= 1'b0;
        end else if (valid_stage2 && valid_stage4) begin
            product <= (z2 << 2) + (z1 << 1) + z0;
            valid_stage5 <= 1'b1;
        end else begin
            valid_stage5 <= 1'b0;
        end
    end

endmodule