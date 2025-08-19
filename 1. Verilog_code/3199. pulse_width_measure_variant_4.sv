//SystemVerilog
module pulse_width_measure #(
    parameter COUNTER_WIDTH = 32
)(
    input clk,
    input pulse_in,
    output reg [COUNTER_WIDTH-1:0] width_count
);

reg last_state;
reg measuring;
wire [COUNTER_WIDTH-1:0] next_count;

// Kogge-Stone adder for incrementing counter
wire [COUNTER_WIDTH-1:0] p, g;  // Generate and propagate signals
wire [COUNTER_WIDTH-1:0] p_level[5:0], g_level[5:0]; // Log2(32)=5 levels for 32-bit adder
wire [COUNTER_WIDTH-1:0] carry;
wire [COUNTER_WIDTH-1:0] sum;

// Initial propagate and generate (Level 0)
genvar i;
generate
    for(i = 0; i < COUNTER_WIDTH; i = i + 1) begin : gen_pg_init
        assign p[i] = width_count[i] ^ 1'b1; // XOR with increment value (1)
        assign g[i] = width_count[i] & 1'b1; // AND with increment value (1)
        assign p_level[0][i] = p[i];
        assign g_level[0][i] = g[i];
    end
endgenerate

// Kogge-Stone parallel prefix network
// Level 1 - stride 1
genvar l1;
generate
    for(l1 = 0; l1 < COUNTER_WIDTH; l1 = l1 + 1) begin : gen_level_1
        if(l1 >= 1) begin
            assign g_level[1][l1] = g_level[0][l1] | (p_level[0][l1] & g_level[0][l1-1]);
            assign p_level[1][l1] = p_level[0][l1] & p_level[0][l1-1];
        end else begin
            assign g_level[1][l1] = g_level[0][l1];
            assign p_level[1][l1] = p_level[0][l1];
        end
    end
endgenerate

// Level 2 - stride 2
genvar l2;
generate
    for(l2 = 0; l2 < COUNTER_WIDTH; l2 = l2 + 1) begin : gen_level_2
        if(l2 >= 2) begin
            assign g_level[2][l2] = g_level[1][l2] | (p_level[1][l2] & g_level[1][l2-2]);
            assign p_level[2][l2] = p_level[1][l2] & p_level[1][l2-2];
        end else begin
            assign g_level[2][l2] = g_level[1][l2];
            assign p_level[2][l2] = p_level[1][l2];
        end
    end
endgenerate

// Level 3 - stride 4
genvar l3;
generate
    for(l3 = 0; l3 < COUNTER_WIDTH; l3 = l3 + 1) begin : gen_level_3
        if(l3 >= 4) begin
            assign g_level[3][l3] = g_level[2][l3] | (p_level[2][l3] & g_level[2][l3-4]);
            assign p_level[3][l3] = p_level[2][l3] & p_level[2][l3-4];
        end else begin
            assign g_level[3][l3] = g_level[2][l3];
            assign p_level[3][l3] = p_level[2][l3];
        end
    end
endgenerate

// Level 4 - stride 8
genvar l4;
generate
    for(l4 = 0; l4 < COUNTER_WIDTH; l4 = l4 + 1) begin : gen_level_4
        if(l4 >= 8) begin
            assign g_level[4][l4] = g_level[3][l4] | (p_level[3][l4] & g_level[3][l4-8]);
            assign p_level[4][l4] = p_level[3][l4] & p_level[3][l4-8];
        end else begin
            assign g_level[4][l4] = g_level[3][l4];
            assign p_level[4][l4] = p_level[3][l4];
        end
    end
endgenerate

// Level 5 - stride 16
genvar l5;
generate
    for(l5 = 0; l5 < COUNTER_WIDTH; l5 = l5 + 1) begin : gen_level_5
        if(l5 >= 16) begin
            assign g_level[5][l5] = g_level[4][l5] | (p_level[4][l5] & g_level[4][l5-16]);
            assign p_level[5][l5] = p_level[4][l5] & p_level[4][l5-16];
        end else begin
            assign g_level[5][l5] = g_level[4][l5];
            assign p_level[5][l5] = p_level[4][l5];
        end
    end
endgenerate

// Calculate carry bits
assign carry[0] = 1'b0; // No carry-in
genvar k;
generate
    for(k = 1; k < COUNTER_WIDTH; k = k + 1) begin : gen_carry
        assign carry[k] = g_level[5][k-1];
    end
endgenerate

// Calculate sum
genvar s;
generate
    for(s = 0; s < COUNTER_WIDTH; s = s + 1) begin : gen_sum
        assign sum[s] = p[s] ^ carry[s];
    end
endgenerate

assign next_count = sum;

always @(posedge clk) begin
    last_state <= pulse_in;
    
    if (pulse_in && !last_state) begin
        measuring <= 1;
        width_count <= 0;
    end else if (!pulse_in && last_state) begin
        measuring <= 0;
    end else if (measuring) begin
        width_count <= next_count;
    end
end

endmodule