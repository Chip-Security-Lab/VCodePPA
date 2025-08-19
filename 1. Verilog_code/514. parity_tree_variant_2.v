module booth_multiplier(
    input [15:0] multiplicand,
    input [15:0] multiplier,
    output reg [31:0] product
);

    reg [15:0] A;
    reg [15:0] Q;
    reg Q_1;
    reg [15:0] M;
    integer i;

    always @(*) begin
        A = 16'b0;
        Q = multiplier;
        Q_1 = 1'b0;
        M = multiplicand;
        product = 32'b0;

        for (i = 0; i < 16; i = i + 1) begin
            case ({Q[0], Q_1})
                2'b00, 2'b11: {A, Q, Q_1} = {A[15], A, Q};
                2'b01: begin
                    A = A + M;
                    {A, Q, Q_1} = {A[15], A, Q};
                end
                2'b10: begin
                    A = A - M;
                    {A, Q, Q_1} = {A[15], A, Q};
                end
            endcase
        end

        product = {A, Q};
    end
endmodule

module parity_tree(
    input [15:0] data,
    output even_par
);
    wire [7:0] level1 = {
        data[15] ^ data[14],
        data[13] ^ data[12],
        data[11] ^ data[10],
        data[9] ^ data[8],
        data[7] ^ data[6],
        data[5] ^ data[4],
        data[3] ^ data[2],
        data[1] ^ data[0]
    };
    
    wire [3:0] level2 = {
        level1[7] ^ level1[6],
        level1[5] ^ level1[4],
        level1[3] ^ level1[2],
        level1[1] ^ level1[0]
    };
    
    wire [1:0] level3 = {
        level2[3] ^ level2[2],
        level2[1] ^ level2[0]
    };
    
    assign even_par = level3[0] ^ level3[1];
endmodule