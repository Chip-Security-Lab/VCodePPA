//SystemVerilog
module eth_crc_gen (
    input wire [7:0] data_in,
    input wire crc_en,
    input wire crc_init,
    input wire clk,
    output wire [31:0] crc_out
);
    // Internal signals
    wire [31:0] crc_reg;
    wire [31:0] next_crc;
    wire [31:0] ks_adder_result;
    
    // CRC Register Control submodule
    crc_register_control u_crc_register (
        .clk(clk),
        .crc_init(crc_init),
        .crc_en(crc_en),
        .next_crc(next_crc),
        .crc_reg(crc_reg)
    );
    
    // CRC Calculation Logic submodule
    crc_calculation_logic u_crc_calc (
        .data_in(data_in),
        .crc_reg(crc_reg),
        .next_crc(next_crc)
    );
    
    // CRC Output Generation submodule
    crc_output_generation u_crc_output (
        .crc_reg(crc_reg),
        .crc_out(crc_out)
    );
endmodule

// CRC Register Control Module
module crc_register_control (
    input wire clk,
    input wire crc_init,
    input wire crc_en,
    input wire [31:0] next_crc,
    output reg [31:0] crc_reg
);
    always @(posedge clk) begin
        if (crc_init)
            crc_reg <= 32'hFFFFFFFF;
        else if (crc_en)
            crc_reg <= next_crc;
    end
endmodule

// CRC Calculation Logic Module
module crc_calculation_logic (
    input wire [7:0] data_in,
    input wire [31:0] crc_reg,
    output wire [31:0] next_crc
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: crc_gen_loop
            assign next_crc[i] = crc_reg[24+i] ^ data_in[i] ^ crc_reg[31];
        end
    endgenerate
    
    assign next_crc[31:8] = crc_reg[23:0];
endmodule

// CRC Output Generation Module
module crc_output_generation (
    input wire [31:0] crc_reg,
    output wire [31:0] crc_out
);
    wire [31:0] ks_adder_result;
    
    // Kogge-Stone adder for CRC output computation
    kogge_stone_adder #(
        .WIDTH(32)
    ) ks_adder_inst (
        .a(~crc_reg),
        .b(32'h00000000),
        .cin(1'b0),
        .sum(ks_adder_result)
    );
    
    // Bit reordering for the final CRC output
    assign crc_out = {
        ks_adder_result[24], ks_adder_result[25], ks_adder_result[26], ks_adder_result[27],
        ks_adder_result[28], ks_adder_result[29], ks_adder_result[30], ks_adder_result[31],
        ks_adder_result[16], ks_adder_result[17], ks_adder_result[18], ks_adder_result[19],
        ks_adder_result[20], ks_adder_result[21], ks_adder_result[22], ks_adder_result[23],
        ks_adder_result[8], ks_adder_result[9], ks_adder_result[10], ks_adder_result[11],
        ks_adder_result[12], ks_adder_result[13], ks_adder_result[14], ks_adder_result[15],
        ks_adder_result[0], ks_adder_result[1], ks_adder_result[2], ks_adder_result[3],
        ks_adder_result[4], ks_adder_result[5], ks_adder_result[6], ks_adder_result[7]
    };
endmodule

// Optimized Kogge-Stone Adder Module
module kogge_stone_adder #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum
);
    // Initial propagate and generate stage
    wire [WIDTH-1:0] p_init, g_init;
    propagate_generate_unit #(.WIDTH(WIDTH)) pg_init (
        .a(a),
        .b(b),
        .p(p_init),
        .g(g_init)
    );
    
    // Intermediate propagate and generate signals for each stage
    wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)-1];
    
    // First stage initialization
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: gen_stage0
            assign p_stage[0][j] = p_init[j];
            assign g_stage[0][j] = g_init[j];
        end
    endgenerate
    
    // Kogge-Stone parallel prefix computation
    parallel_prefix_network #(.WIDTH(WIDTH)) prefix_network (
        .p_in(p_stage[0]),
        .g_in(g_stage[0]),
        .p_out(p_stage),
        .g_out(g_stage)
    );
    
    // Compute carry signals and sum
    carry_sum_generation #(.WIDTH(WIDTH)) sum_gen (
        .p_init(p_init),
        .p_final(p_stage[$clog2(WIDTH)-1]),
        .g_final(g_stage[$clog2(WIDTH)-1]),
        .cin(cin),
        .sum(sum)
    );
endmodule

// Propagate-Generate Initial Unit
module propagate_generate_unit #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] p,
    output wire [WIDTH-1:0] g
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_init_pg
            assign p[i] = a[i] ^ b[i];  // Propagate = a XOR b
            assign g[i] = a[i] & b[i];  // Generate = a AND b
        end
    endgenerate
endmodule

// Parallel Prefix Network for Kogge-Stone
module parallel_prefix_network #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] p_in,
    input wire [WIDTH-1:0] g_in,
    output wire [WIDTH-1:0] p_out [0:$clog2(WIDTH)-1],
    output wire [WIDTH-1:0] g_out [0:$clog2(WIDTH)-1]
);
    // Kogge-Stone parallel prefix computation
    genvar stage, idx;
    generate
        // First stage assignment
        for (idx = 0; idx < WIDTH; idx = idx + 1) begin: gen_first_stage
            assign p_out[0][idx] = p_in[idx];
            assign g_out[0][idx] = g_in[idx];
        end
        
        // Remaining stages
        for (stage = 0; stage < $clog2(WIDTH)-1; stage = stage + 1) begin: gen_stage
            for (idx = 0; idx < WIDTH; idx = idx + 1) begin: gen_prefix
                if (idx > (2**(stage+1)-1)) begin
                    // Compute propagate and generate with operator fusion where possible
                    assign p_out[stage+1][idx] = p_out[stage][idx] & p_out[stage][idx-(2**stage)];
                    assign g_out[stage+1][idx] = g_out[stage][idx] | 
                                              (p_out[stage][idx] & g_out[stage][idx-(2**stage)]);
                end else begin
                    // Pass through values for positions without dependencies
                    assign p_out[stage+1][idx] = p_out[stage][idx];
                    assign g_out[stage+1][idx] = g_out[stage][idx];
                end
            end
        end
    endgenerate
endmodule

// Carry and Sum Generation Module
module carry_sum_generation #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] p_init,
    input wire [WIDTH-1:0] p_final,
    input wire [WIDTH-1:0] g_final,
    input wire cin,
    output wire [WIDTH-1:0] sum
);
    // Compute carry signals
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    
    genvar k;
    generate
        for (k = 0; k < WIDTH; k = k + 1) begin: gen_carry
            assign carry[k+1] = g_final[k] | (p_final[k] & carry[k]);
        end
    endgenerate
    
    // Compute sum outputs
    genvar l;
    generate
        for (l = 0; l < WIDTH; l = l + 1) begin: gen_sum
            assign sum[l] = p_init[l] ^ carry[l];
        end
    endgenerate
endmodule