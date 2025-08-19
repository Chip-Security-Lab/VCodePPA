//SystemVerilog
module pipelined_wallace (
    input clk,
    input rst_n,
    input valid_in,
    input [15:0] a,
    input [15:0] b,
    output reg valid_out,
    output [31:0] p
);

    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    
    // Input registers
    reg [15:0] a_reg, b_reg;
    
    // Stage 1: Partial products generation and first reduction
    wire [15:0] pp[15:0];
    reg [15:0] pp_reg[15:0];
    reg [19:0] s1_sum1, s1_sum2, s1_sum3, s1_sum4, s1_sum5, s1_sum6;
    reg [19:0] s1_carry1, s1_carry2, s1_carry3, s1_carry4, s1_carry5, s1_carry6;
    
    // Stage 2: Second reduction
    reg [23:0] s2_sum1, s2_sum2, s2_sum3;
    reg [23:0] s2_carry1, s2_carry2, s2_carry3;
    
    // Stage 3: Third reduction
    reg [31:0] s3_sum, s3_carry;
    
    // Stage 4: Final addition
    reg [31:0] result;

    // Generate partial products
    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) begin : pp_gen
            for (j = 0; j < 16; j = j + 1) begin : pp_bit
                assign pp[i][j] = a_reg[j] & b_reg[i];
            end
        end
    endgenerate

    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            a_reg <= 16'b0;
            b_reg <= 16'b0;
            for (int k = 0; k < 16; k++) begin
                pp_reg[k] <= 16'b0;
            end
            s1_sum1 <= 20'b0; s1_sum2 <= 20'b0; s1_sum3 <= 20'b0;
            s1_sum4 <= 20'b0; s1_sum5 <= 20'b0; s1_sum6 <= 20'b0;
            s1_carry1 <= 20'b0; s1_carry2 <= 20'b0; s1_carry3 <= 20'b0;
            s1_carry4 <= 20'b0; s1_carry5 <= 20'b0; s1_carry6 <= 20'b0;
        end else begin
            valid_stage1 <= valid_in;
            a_reg <= a;
            b_reg <= b;
            for (int k = 0; k < 16; k++) begin
                pp_reg[k] <= pp[k];
            end
            {s1_carry1, s1_sum1} <= {4'b0, pp_reg[0]} + {3'b0, pp_reg[1], 1'b0} + {2'b0, pp_reg[2], 2'b0};
            {s1_carry2, s1_sum2} <= {4'b0, pp_reg[3]} + {3'b0, pp_reg[4], 1'b0} + {2'b0, pp_reg[5], 2'b0};
            {s1_carry3, s1_sum3} <= {4'b0, pp_reg[6]} + {3'b0, pp_reg[7], 1'b0} + {2'b0, pp_reg[8], 2'b0};
            {s1_carry4, s1_sum4} <= {4'b0, pp_reg[9]} + {3'b0, pp_reg[10], 1'b0} + {2'b0, pp_reg[11], 2'b0};
            {s1_carry5, s1_sum5} <= {4'b0, pp_reg[12]} + {3'b0, pp_reg[13], 1'b0} + {2'b0, pp_reg[14], 2'b0};
            {s1_carry6, s1_sum6} <= {19'b0, pp_reg[15]};
        end
    end

    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            s2_sum1 <= 24'b0; s2_sum2 <= 24'b0; s2_sum3 <= 24'b0;
            s2_carry1 <= 24'b0; s2_carry2 <= 24'b0; s2_carry3 <= 24'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            {s2_carry1, s2_sum1} <= {4'b0, s1_sum1} + {3'b0, s1_sum2, 1'b0} + {2'b0, s1_carry1, 2'b0};
            {s2_carry2, s2_sum2} <= {4'b0, s1_sum3} + {3'b0, s1_sum4, 1'b0} + {2'b0, s1_carry2, 2'b0};
            {s2_carry3, s2_sum3} <= {4'b0, s1_sum5} + {3'b0, s1_sum6, 1'b0} + {2'b0, s1_carry3, 2'b0};
        end
    end

    // Pipeline stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage3 <= 1'b0;
            s3_sum <= 32'b0;
            s3_carry <= 32'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            {s3_carry, s3_sum} <= {8'b0, s2_sum1} + {7'b0, s2_sum2, 1'b0} + 
                                 {6'b0, s2_sum3, 2'b0} + {5'b0, s2_carry1, 3'b0} +
                                 {4'b0, s2_carry2, 4'b0} + {3'b0, s2_carry3, 5'b0};
        end
    end

    // Pipeline stage 4
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage4 <= 1'b0;
            valid_out <= 1'b0;
            result <= 32'b0;
        end else begin
            valid_stage4 <= valid_stage3;
            valid_out <= valid_stage4;
            result <= s3_sum + {s3_carry[30:0], 1'b0};
        end
    end

    assign p = result;
endmodule

module full_adder (
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule