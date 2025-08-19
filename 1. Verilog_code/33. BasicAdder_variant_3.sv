//SystemVerilog
module cla_adder_8bit (
    input [7:0] a,
    input [7:0] b,
    input       cin,
    output [7:0] sum,
    output      cout
);

wire [7:0] p; // Propagate signals p[i] = a[i] ^ b[i]
wire [7:0] g; // Generate signals g[i] = a[i] & b[i]
wire [8:0] c; // Carries c[0] = cin, c[1]..c[7] intermediate, c[8] = cout

// Calculate generate and propagate signals for each bit
assign p = a ^ b;
assign g = a & b;

// Assign the input carry to the first carry signal
assign c[0] = cin;

// Intermediate propagate products: p_chain[i][j] = p[i] & p[i-1] & ... & p[j]
// This structure breaks down complex AND terms into chained 2-input ANDs,
// which can help synthesis tools optimize for fan-in and logic sharing,
// potentially improving PPA metrics like speed and area.
wire p_chain [7:0][7:0];

// Base cases: p_chain[i][i] = p[i]
assign p_chain[0][0] = p[0];
assign p_chain[1][1] = p[1];
assign p_chain[2][2] = p[2];
assign p_chain[3][3] = p[3];
assign p_chain[4][4] = p[4];
assign p_chain[5][5] = p[5];
assign p_chain[6][6] = p[6];
assign p_chain[7][7] = p[7];

// Recursive calculation: p_chain[i][j] = p_chain[i][j+1] & p[j] for i > j
assign p_chain[1][0] = p_chain[1][1] & p[0];

assign p_chain[2][1] = p_chain[2][2] & p[1];
assign p_chain[2][0] = p_chain[2][1] & p[0];

assign p_chain[3][2] = p_chain[3][3] & p[2];
assign p_chain[3][1] = p_chain[3][2] & p[1];
assign p_chain[3][0] = p_chain[3][1] & p[0];

assign p_chain[4][3] = p_chain[4][4] & p[3];
assign p_chain[4][2] = p_chain[4][3] & p[2];
assign p_chain[4][1] = p_chain[4][2] & p[1];
assign p_chain[4][0] = p_chain[4][1] & p[0];

assign p_chain[5][4] = p_chain[5][5] & p[4];
assign p_chain[5][3] = p_chain[5][4] & p[3];
assign p_chain[5][2] = p_chain[5][3] & p[2];
assign p_chain[5][1] = p_chain[5][2] & p[1];
assign p_chain[5][0] = p_chain[5][1] & p[0];

assign p_chain[6][5] = p_chain[6][6] & p[5];
assign p_chain[6][4] = p_chain[6][5] & p[4];
assign p_chain[6][3] = p_chain[6][4] & p[3];
assign p_chain[6][2] = p_chain[6][3] & p[2];
assign p_chain[6][1] = p_chain[6][2] & p[1];
assign p_chain[6][0] = p_chain[6][1] & p[0];

assign p_chain[7][6] = p_chain[7][7] & p[6];
assign p_chain[7][5] = p_chain[7][6] & p[5];
assign p_chain[7][4] = p_chain[7][5] & p[4];
assign p_chain[7][3] = p_chain[7][4] & p[3];
assign p_chain[7][2] = p_chain[7][3] & p[2];
assign p_chain[7][1] = p_chain[7][2] & p[1];
assign p_chain[7][0] = p_chain[7][1] & p[0];


// Calculate carries using carry-lookahead logic
// c[i+1] = g[i] | p[i]c[i]
// Expanded form using intermediate propagate chains:
// c[k+1] = g[k] | (p[k] & g[k-1]) | (p[k]&p[k-1] & g[k-2]) | ... | (p[k]&...&p[0] & c[0])
assign c[1] = g[0] | (p_chain[0][0] & c[0]);
assign c[2] = g[1] | (p_chain[1][1] & g[0]) | (p_chain[1][0] & c[0]);
assign c[3] = g[2] | (p_chain[2][2] & g[1]) | (p_chain[2][1] & g[0]) | (p_chain[2][0] & c[0]);
assign c[4] = g[3] | (p_chain[3][3] & g[2]) | (p_chain[3][2] & g[1]) | (p_chain[3][1] & g[0]) | (p_chain[3][0] & c[0]);
assign c[5] = g[4] | (p_chain[4][4] & g[3]) | (p_chain[4][3] & g[2]) | (p_chain[4][2] & g[1]) | (p_chain[4][1] & g[0]) | (p_chain[4][0] & c[0]);
assign c[6] = g[5] | (p_chain[5][5] & g[4]) | (p_chain[5][4] & g[3]) | (p_chain[5][3] & g[2]) | (p_chain[5][2] & g[1]) | (p_chain[5][1] & g[0]) | (p_chain[5][0] & c[0]);
assign c[7] = g[6] | (p_chain[6][6] & g[5]) | (p_chain[6][5] & g[4]) | (p_chain[6][4] & g[3]) | (p_chain[6][3] & g[2]) | (p_chain[6][2] & g[1]) | (p_chain[6][1] & g[0]) | (p_chain[6][0] & c[0]);
assign c[8] = g[7] | (p_chain[7][7] & g[6]) | (p_chain[7][6] & g[5]) | (p_chain[7][5] & g[4]) | (p_chain[7][4] & g[3]) | (p_chain[7][3] & g[2]) | (p_chain[7][2] & g[1]) | (p_chain[7][1] & g[0]) | (p_chain[7][0] & c[0]);


// Assign the final output carry
assign cout = c[8];

// Calculate sum bits
// sum[i] = p[i] ^ c[i]
assign sum[0] = p[0] ^ c[0];
assign sum[1] = p[1] ^ c[1];
assign sum[2] = p[2] ^ c[2];
assign sum[3] = p[3] ^ c[3];
assign sum[4] = p[4] ^ c[4];
assign sum[5] = p[5] ^ c[5];
assign sum[6] = p[6] ^ c[6];
assign sum[7] = p[7] ^ c[7];

endmodule