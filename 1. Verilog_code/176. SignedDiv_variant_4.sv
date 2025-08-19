//SystemVerilog
module SignedDiv(
    input signed [7:0] num, den,
    output signed [7:0] q
);
    wire [7:0] abs_num, abs_den;
    wire [7:0] abs_q;
    wire sign_q;
    
    SignExtractor sign_extractor(
        .num(num),
        .den(den),
        .abs_num(abs_num),
        .abs_den(abs_den),
        .sign_q(sign_q)
    );
    
    UnsignedDivider unsigned_divider(
        .num(abs_num),
        .den(abs_den),
        .q(abs_q)
    );
    
    SignApplier sign_applier(
        .abs_q(abs_q),
        .sign_q(sign_q),
        .q(q)
    );
endmodule

module SignExtractor(
    input signed [7:0] num, den,
    output [7:0] abs_num, abs_den,
    output sign_q
);
    wire [7:0] num_comp, den_comp;
    wire [7:0] num_plus_1, den_plus_1;
    
    assign num_comp = ~num;
    assign den_comp = ~den;
    
    assign num_plus_1 = num_comp + 1'b1;
    assign den_plus_1 = den_comp + 1'b1;
    
    assign abs_num = num[7] ? num_plus_1 : num;
    assign abs_den = den[7] ? den_plus_1 : den;
    assign sign_q = num[7] ^ den[7];
endmodule

module UnsignedDivider(
    input [7:0] num, den,
    output [7:0] q
);
    reg [7:0] quotient;
    reg [7:0] remainder;
    reg [7:0] temp_num;
    integer i;
    
    always @(*) begin
        quotient = 8'b0;
        remainder = 8'b0;
        temp_num = num;
        
        for(i = 7; i >= 0; i = i - 1) begin
            remainder = {remainder[6:0], temp_num[i]};
            if(remainder >= den) begin
                remainder = remainder - den;
                quotient[i] = 1'b1;
            end
        end
    end
    
    assign q = (den != 0) ? quotient : 8'h80;
endmodule

module SignApplier(
    input [7:0] abs_q,
    input sign_q,
    output signed [7:0] q
);
    wire [7:0] abs_q_comp;
    wire [7:0] abs_q_plus_1;
    
    assign abs_q_comp = ~abs_q;
    assign abs_q_plus_1 = abs_q_comp + 1'b1;
    
    assign q = sign_q ? abs_q_plus_1 : abs_q;
endmodule