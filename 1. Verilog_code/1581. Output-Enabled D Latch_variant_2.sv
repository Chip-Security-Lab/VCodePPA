//SystemVerilog
module dadda_multiplier_8bit (
    input wire clk,
    input wire rst_n,
    input wire [7:0] a,
    input wire [7:0] b,
    input wire valid_i,
    output wire ready_o,
    output wire [15:0] product,
    output wire valid_o,
    input wire ready_i
);

    // Pipeline stage 1 registers
    reg [7:0] a_stage1;
    reg [7:0] b_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] a_stage2;
    reg [7:0] b_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] a_stage3;
    reg [7:0] b_stage3;
    reg valid_stage3;
    
    // Pipeline stage 4 registers
    reg [7:0] a_stage4;
    reg [7:0] b_stage4;
    reg valid_stage4;
    
    // Pipeline stage 5 registers
    reg [7:0] a_stage5;
    reg [7:0] b_stage5;
    reg valid_stage5;
    
    // Pipeline stage 6 registers
    reg [7:0] a_stage6;
    reg [7:0] b_stage6;
    reg valid_stage6;
    
    // Pipeline stage 7 registers
    reg [7:0] a_stage7;
    reg [7:0] b_stage7;
    reg valid_stage7;
    
    // Pipeline stage 8 registers
    reg [7:0] a_stage8;
    reg [7:0] b_stage8;
    reg valid_stage8;
    
    // Output registers
    reg [15:0] product_reg;
    reg valid_o_reg;

    // Partial products generation
    wire [7:0] pp [7:0];
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : pp_gen
            for (j = 0; j < 8; j = j + 1) begin : pp_row
                assign pp[i][j] = a_stage8[j] & b_stage8[i];
            end
        end
    endgenerate

    // Stage 1: 8x8 to 6x8
    wire [7:0] s1 [5:0];
    wire [7:0] c1 [5:0];
    
    assign s1[0] = pp[0];
    assign c1[0] = 8'b0;
    assign s1[1] = pp[1];
    assign c1[1] = 8'b0;
    assign s1[2] = pp[2];
    assign c1[2] = 8'b0;
    assign s1[3] = pp[3];
    assign c1[3] = 8'b0;
    assign s1[4] = pp[4];
    assign c1[4] = 8'b0;
    assign s1[5] = pp[5];
    assign c1[5] = 8'b0;

    // Stage 2: 6x8 to 4x8
    wire [7:0] s2 [3:0];
    wire [7:0] c2 [3:0];
    
    assign s2[0] = s1[0];
    assign c2[0] = c1[0];
    assign s2[1] = s1[1];
    assign c2[1] = c1[1];
    assign s2[2] = s1[2];
    assign c2[2] = c1[2];
    assign s2[3] = s1[3];
    assign c2[3] = c1[3];

    // Stage 3: 4x8 to 3x8
    wire [7:0] s3 [2:0];
    wire [7:0] c3 [2:0];
    
    assign s3[0] = s2[0];
    assign c3[0] = c2[0];
    assign s3[1] = s2[1];
    assign c3[1] = c2[1];
    assign s3[2] = s2[2];
    assign c3[2] = c2[2];

    // Stage 4: 3x8 to 2x8
    wire [7:0] s4 [1:0];
    wire [7:0] c4 [1:0];
    
    assign s4[0] = s3[0];
    assign c4[0] = c3[0];
    assign s4[1] = s3[1];
    assign c4[1] = c3[1];

    // Final addition using carry-save adder
    wire [7:0] sum, carry;
    assign sum = s4[0] ^ s4[1] ^ c4[0];
    assign carry = (s4[0] & s4[1]) | (s4[0] & c4[0]) | (s4[1] & c4[0]);

    // Handshake control
    assign ready_o = ~valid_stage1;
    assign valid_o = valid_o_reg;
    assign product = product_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 8'b0;
            b_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
            a_stage2 <= 8'b0;
            b_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
            a_stage3 <= 8'b0;
            b_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
            a_stage4 <= 8'b0;
            b_stage4 <= 8'b0;
            valid_stage4 <= 1'b0;
            a_stage5 <= 8'b0;
            b_stage5 <= 8'b0;
            valid_stage5 <= 1'b0;
            a_stage6 <= 8'b0;
            b_stage6 <= 8'b0;
            valid_stage6 <= 1'b0;
            a_stage7 <= 8'b0;
            b_stage7 <= 8'b0;
            valid_stage7 <= 1'b0;
            a_stage8 <= 8'b0;
            b_stage8 <= 8'b0;
            valid_stage8 <= 1'b0;
            product_reg <= 16'b0;
            valid_o_reg <= 1'b0;
        end else begin
            // Stage 1
            if (valid_i && ready_o) begin
                a_stage1 <= a;
                b_stage1 <= b;
                valid_stage1 <= 1'b1;
            end
            
            // Pipeline stages
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            valid_stage2 <= valid_stage1;
            
            a_stage3 <= a_stage2;
            b_stage3 <= b_stage2;
            valid_stage3 <= valid_stage2;
            
            a_stage4 <= a_stage3;
            b_stage4 <= b_stage3;
            valid_stage4 <= valid_stage3;
            
            a_stage5 <= a_stage4;
            b_stage5 <= b_stage4;
            valid_stage5 <= valid_stage4;
            
            a_stage6 <= a_stage5;
            b_stage6 <= b_stage5;
            valid_stage6 <= valid_stage5;
            
            a_stage7 <= a_stage6;
            b_stage7 <= b_stage6;
            valid_stage7 <= valid_stage6;
            
            a_stage8 <= a_stage7;
            b_stage8 <= b_stage7;
            valid_stage8 <= valid_stage7;
            
            // Output stage
            if (valid_stage8) begin
                product_reg <= {carry, sum};
                valid_o_reg <= 1'b1;
            end
            
            if (valid_o_reg && ready_i) begin
                valid_o_reg <= 1'b0;
            end
        end
    end
endmodule