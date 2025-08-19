//SystemVerilog
module Div4(
    input [7:0] D, d,
    output [7:0] Q, R
);

    wire [7:0] quotient;
    wire [7:0] remainder;
    
    Div4_Control control(
        .D(D),
        .d(d),
        .Q(quotient),
        .R(remainder)
    );
    
    assign Q = quotient;
    assign R = remainder;
    
endmodule

module Div4_Control(
    input [7:0] D,
    input [7:0] d,
    output [7:0] Q,
    output [7:0] R
);
    
    wire [7:0] borrow;
    wire [8:0] R_temp;
    
    Div4_Shift shift(
        .D(D),
        .d(d),
        .borrow(borrow),
        .R_temp(R_temp)
    );
    
    Div4_Quotient quotient(
        .borrow(borrow),
        .Q(Q)
    );
    
    assign R = R_temp[7:0];
    
endmodule

module Div4_Shift(
    input [7:0] D,
    input [7:0] d,
    output [7:0] borrow,
    output [8:0] R_temp
);
    
    reg [8:0] R_reg;
    reg [7:0] borrow_reg;
    integer i;
    
    always @(*) begin
        R_reg = {1'b0, D};
        borrow_reg = 0;
        
        for(i = 0; i < 8; i = i + 1) begin
            R_reg = {R_reg[7:0], 1'b0};
            borrow_reg[i] = (R_reg[8:1] >= d);
            if(borrow_reg[i]) begin
                R_reg[8:1] = R_reg[8:1] - d;
            end
        end
    end
    
    assign R_temp = R_reg;
    assign borrow = borrow_reg;
    
endmodule

module Div4_Quotient(
    input [7:0] borrow,
    output [7:0] Q
);
    
    assign Q = borrow; // Directly assign borrow to Q as it represents the quotient
    
endmodule