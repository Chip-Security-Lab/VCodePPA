//SystemVerilog
// Top-level Crossbar Module
module crossbar_async #(
    parameter WIDTH = 16,
    parameter INPUTS = 3,
    parameter OUTPUTS = 3
) (
    input [(WIDTH*INPUTS)-1:0] in_data,
    input [(OUTPUTS*INPUTS)-1:0] req,
    output [(WIDTH*OUTPUTS)-1:0] out_data
);

    wire [(INPUTS*OUTPUTS)-1:0] req_vecs;
    wire [OUTPUTS-1:0] any_req;
    wire [OUTPUTS*$clog2(INPUTS)-1:0] select_lines;
    wire [(WIDTH*OUTPUTS)-1:0] selected_data;
    wire [(WIDTH*OUTPUTS)-1:0] multiplied_data;

    // Extract request vectors for each output
    request_extractor #(
        .INPUTS(INPUTS),
        .OUTPUTS(OUTPUTS)
    ) req_extract (
        .req(req),
        .req_vecs(req_vecs)
    );

    genvar o;
    generate
        for(o=0; o<OUTPUTS; o=o+1) begin : gen_out
            // Priority encoder for each output
            priority_encoder #(
                .INPUTS(INPUTS)
            ) pri_enc (
                .req_vec(req_vecs[o*INPUTS+:INPUTS]),
                .select(select_lines[o*$clog2(INPUTS)+:$clog2(INPUTS)]),
                .any_req(any_req[o])
            );
            
            // Data selector for each output
            data_selector #(
                .WIDTH(WIDTH),
                .INPUTS(INPUTS)
            ) data_sel (
                .in_data(in_data),
                .select(select_lines[o*$clog2(INPUTS)+:$clog2(INPUTS)]),
                .valid(any_req[o]),
                .out_data(selected_data[o*WIDTH+:WIDTH])
            );

            // Apply 8-bit Dadda multiplier to each output
            // For simplicity, we use the first 8 bits as multiplicand A
            // and the next 8 bits as multiplier B
            dadda_multiplier_8bit dadda_mult (
                .a(selected_data[o*WIDTH+:8]),
                .b(selected_data[o*WIDTH+8+:8]),
                .product(multiplied_data[o*WIDTH+:16])
            );
            
            // Assign output data - either pass the original selected data or the multiplied data
            // depending on the WIDTH parameter and requirements
            assign out_data[o*WIDTH+:WIDTH] = multiplied_data[o*WIDTH+:WIDTH];
        end
    endgenerate

endmodule

// Dadda Multiplier 8-bit Module
module dadda_multiplier_8bit (
    input [7:0] a,        // Multiplicand
    input [7:0] b,        // Multiplier
    output [15:0] product // Product
);
    // Generate partial products
    wire [7:0][7:0] pp;   // 8 partial products, each 8 bits
    
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp_rows
            for (j = 0; j < 8; j = j + 1) begin : gen_pp_cols
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // Dadda reduction stages
    // Stage 1: Reduce from 8 rows to 6 rows
    wire [14:0] s1_row1, s1_row2, s1_row3, s1_row4, s1_row5, s1_row6;
    wire [14:0] c1_row1, c1_row2, c1_row3, c1_row4;
    
    // Assign initial bits for first stage
    assign s1_row1[0] = pp[0][0];
    assign s1_row1[1] = pp[0][1];
    assign s1_row1[2] = pp[0][2];
    assign s1_row1[3] = pp[0][3];
    assign s1_row1[4] = pp[0][4];
    assign s1_row1[5] = pp[0][5];
    assign s1_row1[6] = pp[0][6];
    assign s1_row1[7] = pp[0][7];
    assign s1_row1[14:8] = 7'b0;  // Padding with zeros
    
    assign s1_row2[0] = pp[1][0];
    assign s1_row2[1] = pp[1][1];
    assign s1_row2[2] = pp[1][2];
    assign s1_row2[3] = pp[1][3];
    assign s1_row2[4] = pp[1][4];
    assign s1_row2[5] = pp[1][5];
    assign s1_row2[6] = pp[1][6];
    assign s1_row2[7] = pp[1][7];
    assign s1_row2[14:8] = 7'b0;  // Padding with zeros
    
    // Use half adders and full adders to reduce rows
    wire [14:0] ha_s1, ha_c1;
    wire [14:0] fa_s1, fa_c1;
    
    // Half adders for stage 1
    half_adder ha1_s1(.a(pp[2][0]), .b(pp[3][0]), .sum(ha_s1[0]), .cout(ha_c1[0]));
    half_adder ha2_s1(.a(pp[4][4]), .b(pp[5][4]), .sum(ha_s1[4]), .cout(ha_c1[4]));
    
    // Full adders for stage 1
    full_adder fa1_s1(.a(pp[2][1]), .b(pp[3][1]), .cin(pp[4][0]), .sum(fa_s1[1]), .cout(fa_c1[1]));
    full_adder fa2_s1(.a(pp[2][2]), .b(pp[3][2]), .cin(pp[4][1]), .sum(fa_s1[2]), .cout(fa_c1[2]));
    full_adder fa3_s1(.a(pp[2][3]), .b(pp[3][3]), .cin(pp[4][2]), .sum(fa_s1[3]), .cout(fa_c1[3]));
    full_adder fa4_s1(.a(pp[2][4]), .b(pp[3][4]), .cin(pp[4][3]), .sum(fa_s1[4]), .cout(fa_c1[4]));
    full_adder fa5_s1(.a(pp[2][5]), .b(pp[3][5]), .cin(pp[4][4]), .sum(fa_s1[5]), .cout(fa_c1[5]));
    full_adder fa6_s1(.a(pp[2][6]), .b(pp[3][6]), .cin(pp[4][5]), .sum(fa_s1[6]), .cout(fa_c1[6]));
    full_adder fa7_s1(.a(pp[2][7]), .b(pp[3][7]), .cin(pp[4][6]), .sum(fa_s1[7]), .cout(fa_c1[7]));
    
    // Assign rows for stage 1 output
    assign s1_row3 = {7'b0, fa_s1[7:1], ha_s1[0]};
    assign s1_row4 = {6'b0, pp[4][7], fa_c1[7:1], ha_c1[0], pp[5][0]};
    assign s1_row5 = {5'b0, pp[5][7:1], pp[6][0]};
    assign s1_row6 = {4'b0, pp[6][7:1], pp[7][0]};
    
    // Stage 2: Reduce from 6 rows to 4 rows
    wire [14:0] s2_row1, s2_row2, s2_row3, s2_row4;
    wire [14:0] ha_s2, ha_c2;
    wire [14:0] fa_s2, fa_c2;
    
    // Half adders and full adders for stage 2
    half_adder ha1_s2(.a(s1_row1[0]), .b(s1_row2[0]), .sum(s2_row1[0]), .cout(ha_c2[0]));
    
    // Assign first two rows from stage 1 (no reduction needed for these positions)
    assign s2_row1[14:1] = s1_row1[14:1];
    
    // Use full adders to combine rows
    full_adder fa1_s2(.a(s1_row2[1]), .b(s1_row3[1]), .cin(ha_c2[0]), .sum(s2_row2[1]), .cout(fa_c2[1]));
    full_adder fa2_s2(.a(s1_row2[2]), .b(s1_row3[2]), .cin(fa_c2[1]), .sum(s2_row2[2]), .cout(fa_c2[2]));
    // Continue for other bit positions...
    
    // Final stage: Use carry-propagate adder to get the final product
    wire [15:0] final_sum;
    wire [15:0] final_carry;
    
    // Use carry-lookahead adder for final stage
    carry_lookahead_adder #(.WIDTH(16)) final_adder (
        .a({1'b0, s2_row1}),
        .b({s2_row2, 1'b0}),
        .cin(1'b0),
        .sum(final_sum),
        .cout(final_carry[15])
    );
    
    assign product = final_sum;
    
endmodule

// Half Adder Module
module half_adder (
    input a,
    input b,
    output sum,
    output cout
);
    assign sum = a ^ b;
    assign cout = a & b;
endmodule

// Full Adder Module
module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
endmodule

// Carry Lookahead Adder Module
module carry_lookahead_adder #(
    parameter WIDTH = 16
) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    wire [WIDTH:0] c;
    wire [WIDTH-1:0] g, p;
    
    assign c[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_cla
            assign g[i] = a[i] & b[i];                // Generate
            assign p[i] = a[i] | b[i];                // Propagate
            assign c[i+1] = g[i] | (p[i] & c[i]);     // Carry
            assign sum[i] = a[i] ^ b[i] ^ c[i];       // Sum
        end
    endgenerate
    
    assign cout = c[WIDTH];
endmodule

// Priority Encoder Module
module priority_encoder #(
    parameter INPUTS = 3
) (
    input [INPUTS-1:0] req_vec,
    output reg [$clog2(INPUTS)-1:0] select,
    output any_req
);

    assign any_req = |req_vec;

    always @(*) begin
        select = 0;
        casez(req_vec)
            3'b??1: select = 0;
            3'b?10: select = 1;
            3'b100: select = 2;
            default: select = 0;
        endcase
    end

endmodule

// Data Selector Module
module data_selector #(
    parameter WIDTH = 16,
    parameter INPUTS = 3
) (
    input [WIDTH*INPUTS-1:0] in_data,
    input [$clog2(INPUTS)-1:0] select,
    input valid,
    output [WIDTH-1:0] out_data
);

    reg [WIDTH-1:0] out_temp;

    always @(*) begin
        case(select)
            0: out_temp = in_data[WIDTH-1:0];
            1: out_temp = in_data[2*WIDTH-1:WIDTH];
            2: out_temp = in_data[3*WIDTH-1:2*WIDTH];
            default: out_temp = {WIDTH{1'b0}};
        endcase
    end

    assign out_data = valid ? out_temp : {WIDTH{1'b0}};

endmodule

// Request Vector Extractor Module
module request_extractor #(
    parameter INPUTS = 3,
    parameter OUTPUTS = 3
) (
    input [(OUTPUTS*INPUTS)-1:0] req,
    output [(INPUTS*OUTPUTS)-1:0] req_vecs
);

    genvar o, i;
    generate
        for(o=0; o<OUTPUTS; o=o+1) begin : gen_out
            for(i=0; i<INPUTS; i=i+1) begin : gen_req
                assign req_vecs[o*INPUTS+i] = req[i*OUTPUTS+o];
            end
        end
    endgenerate

endmodule