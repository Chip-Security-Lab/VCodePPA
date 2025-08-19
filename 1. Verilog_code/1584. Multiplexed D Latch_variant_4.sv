//SystemVerilog
module booth_multiplier_4bit (
    input wire [3:0] multiplicand,
    input wire [3:0] multiplier,
    output reg [7:0] product
);
    reg [3:0] A;
    reg [3:0] Q;
    reg Q_1;
    reg [3:0] M;
    integer i;

    always @* begin
        A = 4'b0;
        Q = multiplier;
        Q_1 = 1'b0;
        M = multiplicand;
        product = 8'b0;

        for (i = 0; i < 4; i = i + 1) begin
            case ({Q[0], Q_1})
                2'b01: begin
                    A = A + M;
                end
                2'b10: begin
                    A = A - M;
                end
                default: begin
                    A = A;
                end
            endcase

            {A, Q, Q_1} = {A[3], A, Q};
        end

        product = {A, Q};
    end
endmodule