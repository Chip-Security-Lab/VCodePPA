//SystemVerilog
module Gated_AND (
    input                  clk,
    input                  rst_n,
    input                  enable,
    input      [3:0]       vec_a, 
    input      [3:0]       vec_b,
    output reg [3:0]       res
);
    // Forward retimed signals - move registers closer to outputs
    // Instead of registering inputs directly, we register intermediate products
    wire [15:0] pp;
    reg         enable_reg;
    wire [7:0]  mult_result;
    
    // Generate partial products directly from inputs (no input registers)
    // This removes the first stage of registers from original design
    assign pp[0]  = vec_a[0] & vec_b[0];
    assign pp[1]  = vec_a[1] & vec_b[0];
    assign pp[2]  = vec_a[2] & vec_b[0];
    assign pp[3]  = vec_a[3] & vec_b[0];
    
    assign pp[4]  = vec_a[0] & vec_b[1];
    assign pp[5]  = vec_a[1] & vec_b[1];
    assign pp[6]  = vec_a[2] & vec_b[1];
    assign pp[7]  = vec_a[3] & vec_b[1];
    
    assign pp[8]  = vec_a[0] & vec_b[2];
    assign pp[9]  = vec_a[1] & vec_b[2];
    assign pp[10] = vec_a[2] & vec_b[2];
    assign pp[11] = vec_a[3] & vec_b[2];
    
    assign pp[12] = vec_a[0] & vec_b[3];
    assign pp[13] = vec_a[1] & vec_b[3];
    assign pp[14] = vec_a[2] & vec_b[3];
    assign pp[15] = vec_a[3] & vec_b[3];
    
    // Register enable signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_reg <= 1'b0;
        end else begin
            enable_reg <= enable;
        end
    end
    
    // Use optimized multiplier with forward retiming
    dadda_multiplier_4bit dadda_mult (
        .clk        (clk),
        .rst_n      (rst_n),
        .a          (vec_a),
        .b          (vec_b),
        .pp         (pp),
        .product    (mult_result)
    );
    
    // Output gating with enable signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            res <= 4'b0000;
        end else begin
            res <= enable_reg ? mult_result[3:0] : 4'b0000;
        end
    end
endmodule

module dadda_multiplier_4bit (
    input                  clk,
    input                  rst_n,
    input      [3:0]       a,
    input      [3:0]       b,
    input      [15:0]      pp,
    output reg [7:0]       product
);
    // Stage 1: Register the partial products from inputs
    reg  [15:0] pp_reg;
    
    // Register partial products - moved after combinational logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pp_reg <= 16'b0;
        end else begin
            pp_reg <= pp;
        end
    end
    
    // Stage 2: First reduction stage
    wire s11, c11, s12, c12;
    reg  s11_reg, c11_reg, s12_reg, c12_reg;
    
    half_adder ha11 (.a(pp_reg[6]), .b(pp_reg[9]), .sum(s11), .cout(c11));
    half_adder ha12 (.a(pp_reg[7]), .b(pp_reg[10]), .sum(s12), .cout(c12));
    
    // Register first reduction results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s11_reg <= 1'b0;
            c11_reg <= 1'b0;
            s12_reg <= 1'b0;
            c12_reg <= 1'b0;
        end else begin
            s11_reg <= s11;
            c11_reg <= c11;
            s12_reg <= s12;
            c12_reg <= c12;
        end
    end
    
    // Stage 3: Second reduction stage
    wire s21, c21, s22, c22, s23, c23, s24, c24, s25, c25;
    reg  s21_reg, c21_reg, s22_reg, c22_reg, s23_reg, c23_reg;
    reg  s24_reg, c24_reg, s25_reg, c25_reg;
    
    half_adder ha21 (.a(pp_reg[4]), .b(pp_reg[1]), .sum(s21), .cout(c21));
    full_adder fa22 (.a(pp_reg[5]), .b(pp_reg[2]), .cin(pp_reg[8]), .sum(s22), .cout(c22));
    full_adder fa23 (.a(s11_reg), .b(pp_reg[3]), .cin(pp_reg[12]), .sum(s23), .cout(c23));
    full_adder fa24 (.a(s12_reg), .b(pp_reg[11]), .cin(pp_reg[13]), .sum(s24), .cout(c24));
    half_adder ha25 (.a(pp_reg[15]), .b(pp_reg[14]), .sum(s25), .cout(c25));
    
    // Register second reduction results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s21_reg <= 1'b0; c21_reg <= 1'b0;
            s22_reg <= 1'b0; c22_reg <= 1'b0;
            s23_reg <= 1'b0; c23_reg <= 1'b0;
            s24_reg <= 1'b0; c24_reg <= 1'b0;
            s25_reg <= 1'b0; c25_reg <= 1'b0;
        end else begin
            s21_reg <= s21; c21_reg <= c21;
            s22_reg <= s22; c22_reg <= c22;
            s23_reg <= s23; c23_reg <= c23;
            s24_reg <= s24; c24_reg <= c24;
            s25_reg <= s25; c25_reg <= c25;
        end
    end
    
    // Stage 4: Final stage with carry propagate adder
    wire [7:0] row1, row2;
    wire [7:0] final_sum;
    
    assign row1 = {c25_reg, c24_reg, c23_reg, c22_reg, c21_reg, 3'b0};
    assign row2 = {s25_reg, s24_reg, s23_reg, s22_reg, s21_reg, pp_reg[0], 2'b0};
    
    // Final addition
    assign final_sum = row1 + row2;
    
    // Register final product
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 8'b0;
        end else begin
            product <= final_sum;
        end
    end
endmodule

module half_adder (
    input      a, b,
    output     sum, cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

module full_adder (
    input      a, b, cin,
    output     sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule