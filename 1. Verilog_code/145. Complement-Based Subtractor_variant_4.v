module subtractor_complement (
    input wire [7:0] a,
    input wire [7:0] b,
    output reg [7:0] res
);

    wire [7:0] b_complement;
    wire [7:0] carry;
    wire [7:0] sum;
    
    // 补码计算优化
    assign b_complement = ~b + 1'b1;
    
    // 进位生成优化
    assign carry[0] = 1'b0;
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : carry_gen
            assign carry[i] = (a[i-1] & b_complement[i-1]) | 
                            ((a[i-1] | b_complement[i-1]) & carry[i-1]);
        end
    endgenerate
    
    // 和计算优化
    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : sum_gen
            assign sum[j] = a[j] ^ b_complement[j] ^ carry[j];
        end
    endgenerate
    
    always @(*) begin
        res = sum;
    end

endmodule