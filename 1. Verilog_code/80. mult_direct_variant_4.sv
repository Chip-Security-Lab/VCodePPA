//SystemVerilog
module booth_encoder #(parameter N=8) (
    input [N-1:0] b,
    output reg [N/2:0][2:0] booth_code
);
    // Booth encoding for each group of 3 bits
    always @(*) begin
        // Handle first group separately due to boundary condition
        case ({b[1], b[0], 1'b0})
            3'b000: booth_code[0] = 3'b000;
            3'b001: booth_code[0] = 3'b001;
            3'b010: booth_code[0] = 3'b001;
            3'b011: booth_code[0] = 3'b010;
            3'b100: booth_code[0] = 3'b110;
            3'b101: booth_code[0] = 3'b111;
            3'b110: booth_code[0] = 3'b111;
            3'b111: booth_code[0] = 3'b000;
        endcase
    end

    // Handle remaining groups
    always @(*) begin
        for (int i = 1; i < N/2; i++) begin
            case ({b[2*i+1], b[2*i], b[2*i-1]})
                3'b000: booth_code[i] = 3'b000;
                3'b001: booth_code[i] = 3'b001;
                3'b010: booth_code[i] = 3'b001;
                3'b011: booth_code[i] = 3'b010;
                3'b100: booth_code[i] = 3'b110;
                3'b101: booth_code[i] = 3'b111;
                3'b110: booth_code[i] = 3'b111;
                3'b111: booth_code[i] = 3'b000;
            endcase
        end
    end
endmodule

module partial_product #(parameter N=8) (
    input [N-1:0] a,
    input [2:0] booth_code,
    output reg [N:0] pp
);
    // Generate partial product based on booth code
    always @(*) begin
        case (booth_code)
            3'b000: pp = 0;
            3'b001: pp = a;
            3'b010: pp = a << 1;
            3'b110: pp = -a << 1;
            3'b111: pp = -a;
            default: pp = 0;
        endcase
    end
endmodule

module wallace_tree #(parameter N=8) (
    input [N/2:0][N:0] pp,
    output [2*N-1:0] sum
);
    wire [2*N-1:0] stage1 [N/2:0];
    wire [2*N-1:0] stage2 [N/4:0];
    
    // First stage: Shift partial products
    genvar i;
    generate
        for (i = 0; i < N/2; i++) begin
            assign stage1[i] = pp[i] << (2*i);
        end
    endgenerate
    
    // Second stage: First level of addition
    generate
        for (i = 0; i < N/4; i++) begin
            assign stage2[i] = stage1[2*i] + stage1[2*i+1];
        end
    endgenerate
    
    // Final addition
    assign sum = stage2[0] + stage2[1];
endmodule

module mult_direct #(parameter N=8) (
    input [N-1:0] a, b,
    output [2*N-1:0] prod
);
    wire [N/2:0][2:0] booth_code;
    wire [N/2:0][N:0] pp;
    
    // Booth encoding
    booth_encoder #(N) encoder (
        .b(b),
        .booth_code(booth_code)
    );
    
    // Generate partial products
    genvar i;
    generate
        for (i = 0; i <= N/2; i++) begin
            partial_product #(N) pp_gen (
                .a(a),
                .booth_code(booth_code[i]),
                .pp(pp[i])
            );
        end
    endgenerate
    
    // Wallace tree addition
    wallace_tree #(N) tree (
        .pp(pp),
        .sum(prod)
    );
endmodule