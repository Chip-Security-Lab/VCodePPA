//SystemVerilog
module dadda_mult (
    input [3:0] a, b,
    output [7:0] product
);

    // Partial product generation stage
    wire [3:0][7:0] pp;
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_pp
            for (j = 0; j < 4; j = j + 1) begin : gen_pp_bit
                assign pp[i][j+i] = a[i] & b[j];
            end
        end
    endgenerate

    // Pipeline stage 1: Initial reduction
    reg [5:0][7:0] stage1_reg;
    always @(*) begin
        stage1_reg[0] = pp[0];
        stage1_reg[1] = pp[1];
        stage1_reg[2] = pp[2];
        stage1_reg[3] = pp[3];
        stage1_reg[4] = {1'b0, pp[0][7:1]};
        stage1_reg[5] = {2'b0, pp[1][7:2]};
    end

    // Pipeline stage 2: Secondary reduction
    reg [3:0][7:0] stage2_reg;
    always @(*) begin
        stage2_reg[0] = stage1_reg[0];
        stage2_reg[1] = stage1_reg[1] ^ stage1_reg[4];
        stage2_reg[2] = stage1_reg[2] ^ stage1_reg[5];
        stage2_reg[3] = stage1_reg[3];
    end

    // Pipeline stage 3: Final reduction
    reg [2:0][7:0] stage3_reg;
    always @(*) begin
        stage3_reg[0] = stage2_reg[0];
        stage3_reg[1] = stage2_reg[1] ^ stage2_reg[2];
        stage3_reg[2] = stage2_reg[3];
    end

    // Pipeline stage 4: Sum and carry generation
    reg [7:0] sum_reg, carry_reg;
    always @(*) begin
        sum_reg = stage3_reg[0] ^ stage3_reg[1] ^ stage3_reg[2];
        carry_reg = (stage3_reg[0] & stage3_reg[1]) | 
                   (stage3_reg[0] & stage3_reg[2]) | 
                   (stage3_reg[1] & stage3_reg[2]);
    end

    // Pipeline stage 5: Final addition
    reg [7:0] product_reg;
    always @(*) begin
        product_reg = sum_reg + {carry_reg[6:0], 1'b0};
    end

    // Output assignment
    assign product = product_reg;

endmodule