//SystemVerilog
module generic_mult #(parameter WIDTH=8) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);

    wire [WIDTH-1:0] abs_op1 = operand1[WIDTH-1] ? ~operand1 + 1'b1 : operand1;
    wire [WIDTH-1:0] abs_op2 = operand2[WIDTH-1] ? ~operand2 + 1'b1 : operand2;
    wire sign = operand1[WIDTH-1] ^ operand2[WIDTH-1];
    
    reg [2*WIDTH-1:0] abs_product;
    reg [2*WIDTH-1:0] shifted_op1;
    reg [2*WIDTH-1:0] temp_sum;
    
    // LUT for 4-bit multiplication
    reg [7:0] mult_lut [0:15][0:15];
    integer i, j;
    
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                mult_lut[i][j] = i * j;
            end
        end
    end
    
    always @(*) begin
        abs_product = 0;
        shifted_op1 = abs_op1;
        temp_sum = 0;
        
        // Split 8-bit multiplication into four 4-bit multiplications
        for (i = 0; i < 2; i = i + 1) begin
            for (j = 0; j < 2; j = j + 1) begin
                temp_sum = mult_lut[abs_op1[3:0]][abs_op2[3:0]];
                if (i == 1) temp_sum = temp_sum << 4;
                if (j == 1) temp_sum = temp_sum << 4;
                abs_product = abs_product + temp_sum;
            end
        end
    end
    
    assign product = sign ? ~abs_product + 1'b1 : abs_product;

endmodule