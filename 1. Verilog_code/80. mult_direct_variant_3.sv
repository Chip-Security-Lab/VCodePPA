//SystemVerilog
module mult_shift_add #(parameter N=8) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);
    reg [2*N-1:0] result;
    reg [2*N-1:0] temp_a;
    reg [N-1:0] temp_b;
    integer i;
    
    always @(*) begin
        result = 0;
        temp_a = a;
        temp_b = b;
        
        for (i = 0; i < N; i = i + 1) begin
            if (temp_b[0] == 1'b1) begin
                result = result + temp_a;
            end
            temp_a = temp_a << 1;
            temp_b = temp_b >> 1;
        end
    end
    
    assign prod = result;
endmodule