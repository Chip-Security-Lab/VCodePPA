//SystemVerilog
// Top-level module
module async_binary_priority_comp #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [$clog2(WIDTH)-1:0] encoded_output,
    output valid_output
);

    // Internal signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g2, p2;
    wire [WIDTH-1:0] g4, p4;
    wire [WIDTH-1:0] g8, p8;
    wire [WIDTH-1:0] carry;
    
    // Instantiate submodules
    gen_prop_gen #(.WIDTH(WIDTH)) gen_prop_inst (
        .data_vector(data_vector),
        .g(g),
        .p(p)
    );
    
    level1_adder #(.WIDTH(WIDTH)) level1_inst (
        .g(g),
        .p(p),
        .g2(g2),
        .p2(p2)
    );
    
    level2_adder #(.WIDTH(WIDTH)) level2_inst (
        .g2(g2),
        .p2(p2),
        .g4(g4),
        .p4(p4)
    );
    
    level3_adder #(.WIDTH(WIDTH)) level3_inst (
        .g4(g4),
        .p4(p4),
        .g8(g8),
        .p8(p8)
    );
    
    carry_compute #(.WIDTH(WIDTH)) carry_inst (
        .g8(g8),
        .p8(p8),
        .carry(carry)
    );
    
    priority_encoder #(.WIDTH(WIDTH)) encoder_inst (
        .carry(carry),
        .encoded_output(encoded_output)
    );
    
    assign valid_output = |data_vector;

endmodule

// Generate and propagate signals module
module gen_prop_gen #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_vector,
    output [WIDTH-1:0] g,
    output [WIDTH-1:0] p
);

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = data_vector[i];
            assign p[i] = 1'b1;
        end
    endgenerate

endmodule

// First level - 2-bit groups module
module level1_adder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] g,
    input [WIDTH-1:0] p,
    output [WIDTH-1:0] g2,
    output [WIDTH-1:0] p2
);

    genvar j;
    generate
        for(j = 0; j < WIDTH-1; j = j + 2) begin : level1
            assign g2[j+1] = g[j+1] | (p[j+1] & g[j]);
            assign p2[j+1] = p[j+1] & p[j];
            assign g2[j] = g[j];
            assign p2[j] = p[j];
        end
    endgenerate

endmodule

// Second level - 4-bit groups module
module level2_adder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] g2,
    input [WIDTH-1:0] p2,
    output [WIDTH-1:0] g4,
    output [WIDTH-1:0] p4
);

    genvar k;
    generate
        for(k = 0; k < WIDTH-3; k = k + 4) begin : level2
            assign g4[k+3] = g2[k+3] | (p2[k+3] & g2[k+1]);
            assign p4[k+3] = p2[k+3] & p2[k+1];
            assign g4[k+2:k] = g2[k+2:k];
            assign p4[k+2:k] = p2[k+2:k];
        end
    endgenerate

endmodule

// Third level - 8-bit groups module
module level3_adder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] g4,
    input [WIDTH-1:0] p4,
    output [WIDTH-1:0] g8,
    output [WIDTH-1:0] p8
);

    genvar l;
    generate
        for(l = 0; l < WIDTH-7; l = l + 8) begin : level3
            assign g8[l+7] = g4[l+7] | (p4[l+7] & g4[l+3]);
            assign p8[l+7] = p4[l+7] & p4[l+3];
            assign g8[l+6:l] = g4[l+6:l];
            assign p8[l+6:l] = p4[l+6:l];
        end
    endgenerate

endmodule

// Final carry computation module
module carry_compute #(parameter WIDTH = 8)(
    input [WIDTH-1:0] g8,
    input [WIDTH-1:0] p8,
    output [WIDTH-1:0] carry
);

    assign carry[0] = 1'b0;
    genvar m;
    generate
        for(m = 1; m < WIDTH; m = m + 1) begin : final_carry
            assign carry[m] = g8[m-1] | (p8[m-1] & carry[m-1]);
        end
    endgenerate

endmodule

// Priority encoder module
module priority_encoder #(parameter WIDTH = 8)(
    input [WIDTH-1:0] carry,
    output [$clog2(WIDTH)-1:0] encoded_output
);

    reg [$clog2(WIDTH)-1:0] encoder_out;
    integer idx;
    
    always @(*) begin
        encoder_out = 0;
        for (idx = 0; idx < WIDTH; idx = idx + 1)
            if (carry[idx] ^ carry[idx+1]) encoder_out = idx[$clog2(WIDTH)-1:0];
    end
    
    assign encoded_output = encoder_out;

endmodule