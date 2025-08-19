module loop_multi_xnor (input_vecA, input_vecB, output_vec);
    parameter LENGTH = 8;
    input wire [LENGTH-1:0] input_vecA, input_vecB;
    output reg [LENGTH-1:0] output_vec;

    integer i;

    always @(*) begin
        for (i = 0; i < LENGTH; i = i + 1) begin
            output_vec[i] = ~(input_vecA[i] ^ input_vecB[i]);
        end
    end
endmodule