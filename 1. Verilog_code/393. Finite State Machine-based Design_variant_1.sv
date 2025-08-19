//SystemVerilog
module nand2_13 (
    input wire A, B,
    output reg Y
);
    reg state;

    always @(A or B) begin
        if ({A, B} == 2'b00) begin
            state = 1; // NAND(0,0) = 1
        end
        else if ({A, B} == 2'b01) begin
            state = 1; // NAND(0,1) = 1
        end
        else if ({A, B} == 2'b10) begin
            state = 1; // NAND(1,0) = 1
        end
        else if ({A, B} == 2'b11) begin
            state = 0; // NAND(1,1) = 0
        end
    end

    always @(state) begin
        Y = state;
    end
endmodule