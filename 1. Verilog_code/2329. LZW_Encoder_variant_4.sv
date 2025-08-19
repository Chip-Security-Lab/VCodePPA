//SystemVerilog
module LZW_Encoder #(DICT_DEPTH=256) (
    input clk, en,
    input [7:0] data,
    output reg [15:0] code
);
    reg [7:0] dict [DICT_DEPTH-1:0];
    reg [15:0] current_code = 0;
    wire [15:0] next_code;
    
    // Brent-Kung Adder implementation
    BrentKungAdder #(.WIDTH(16)) adder (
        .a(current_code),
        .b(16'h0001),
        .sum(next_code)
    );
    
    always @(posedge clk) begin
        if(en && dict[current_code] == data) begin
            current_code <= next_code;
        end
        else if(en && dict[current_code] != data) begin
            code <= current_code;
            dict[current_code] <= data;
            current_code <= 0;
        end
    end
endmodule

// Brent-Kung Parallel Prefix Adder
module BrentKungAdder #(parameter WIDTH=16) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] p, g; // Propagate and generate signals
    wire [WIDTH-1:0] pg_prefix; // Prefix propagate signals
    wire [WIDTH-1:0] gg_prefix; // Prefix generate signals
    wire [WIDTH-1:0] carry;
    
    // Stage 1: Generate initial p and g values
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // Stage 2: Prefix computation (Brent-Kung tree)
    // Level 1: 2-bit groups
    generate
        for (genvar i = 0; i < WIDTH; i = i + 2) begin : level1
            if (i+1 < WIDTH) begin
                assign pg_prefix[i] = p[i];
                assign gg_prefix[i] = g[i];
                assign pg_prefix[i+1] = p[i+1] & p[i];
                assign gg_prefix[i+1] = g[i+1] | (p[i+1] & g[i]);
            end else begin
                assign pg_prefix[i] = p[i];
                assign gg_prefix[i] = g[i];
            end
        end
    endgenerate
    
    // Level 2: 4-bit groups
    generate
        for (genvar i = 0; i < WIDTH; i = i + 4) begin : level2
            if (i+2 < WIDTH) begin
                assign pg_prefix[i+2] = pg_prefix[i+2];
                assign gg_prefix[i+2] = gg_prefix[i+2];
                
                if (i+3 < WIDTH) begin
                    wire pg_temp = pg_prefix[i+3] & pg_prefix[i+1];
                    wire gg_temp = gg_prefix[i+3] | (pg_prefix[i+3] & gg_prefix[i+1]);
                    assign pg_prefix[i+3] = pg_temp;
                    assign gg_prefix[i+3] = gg_temp;
                end
            end
        end
    endgenerate
    
    // Level 3: 8-bit groups
    generate
        for (genvar i = 0; i < WIDTH; i = i + 8) begin : level3
            if (i+4 < WIDTH) begin
                assign pg_prefix[i+4] = pg_prefix[i+4];
                assign gg_prefix[i+4] = gg_prefix[i+4];
                
                if (i+5 < WIDTH) begin
                    wire pg_temp = pg_prefix[i+5] & pg_prefix[i+3];
                    wire gg_temp = gg_prefix[i+5] | (pg_prefix[i+5] & gg_prefix[i+3]);
                    assign pg_prefix[i+5] = pg_temp;
                    assign gg_prefix[i+5] = gg_temp;
                end
                
                if (i+6 < WIDTH) begin
                    wire pg_temp = pg_prefix[i+6] & pg_prefix[i+3];
                    wire gg_temp = gg_prefix[i+6] | (pg_prefix[i+6] & gg_prefix[i+3]);
                    assign pg_prefix[i+6] = pg_temp;
                    assign gg_prefix[i+6] = gg_temp;
                end
                
                if (i+7 < WIDTH) begin
                    wire pg_temp = pg_prefix[i+7] & pg_prefix[i+3];
                    wire gg_temp = gg_prefix[i+7] | (pg_prefix[i+7] & gg_prefix[i+3]);
                    assign pg_prefix[i+7] = pg_temp;
                    assign gg_prefix[i+7] = gg_temp;
                end
            end
        end
    endgenerate
    
    // Level 4: 16-bit groups (for WIDTH=16)
    generate
        if (WIDTH > 8) begin : level4
            for (genvar i = 0; i < WIDTH; i = i + 16) begin
                if (i+8 < WIDTH) begin
                    assign pg_prefix[i+8] = pg_prefix[i+8];
                    assign gg_prefix[i+8] = gg_prefix[i+8];
                    
                    if (i+9 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+9] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+9] | (pg_prefix[i+9] & gg_prefix[i+7]);
                        assign pg_prefix[i+9] = pg_temp;
                        assign gg_prefix[i+9] = gg_temp;
                    end
                    
                    if (i+10 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+10] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+10] | (pg_prefix[i+10] & gg_prefix[i+7]);
                        assign pg_prefix[i+10] = pg_temp;
                        assign gg_prefix[i+10] = gg_temp;
                    end
                    
                    if (i+11 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+11] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+11] | (pg_prefix[i+11] & gg_prefix[i+7]);
                        assign pg_prefix[i+11] = pg_temp;
                        assign gg_prefix[i+11] = gg_temp;
                    end
                    
                    if (i+12 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+12] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+12] | (pg_prefix[i+12] & gg_prefix[i+7]);
                        assign pg_prefix[i+12] = pg_temp;
                        assign gg_prefix[i+12] = gg_temp;
                    end
                    
                    if (i+13 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+13] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+13] | (pg_prefix[i+13] & gg_prefix[i+7]);
                        assign pg_prefix[i+13] = pg_temp;
                        assign gg_prefix[i+13] = gg_temp;
                    end
                    
                    if (i+14 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+14] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+14] | (pg_prefix[i+14] & gg_prefix[i+7]);
                        assign pg_prefix[i+14] = pg_temp;
                        assign gg_prefix[i+14] = gg_temp;
                    end
                    
                    if (i+15 < WIDTH) begin
                        wire pg_temp = pg_prefix[i+15] & pg_prefix[i+7];
                        wire gg_temp = gg_prefix[i+15] | (pg_prefix[i+15] & gg_prefix[i+7]);
                        assign pg_prefix[i+15] = pg_temp;
                        assign gg_prefix[i+15] = gg_temp;
                    end
                end
            end
        end
    endgenerate
    
    // Calculate all carries
    assign carry[0] = 0; // No carry-in for first bit
    generate
        for (genvar i = 1; i < WIDTH; i = i + 1) begin : gen_carry
            assign carry[i] = gg_prefix[i-1];
        end
    endgenerate
    
    // Calculate sum
    generate
        for (genvar i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule