//SystemVerilog
module rom_secure #(parameter KEY=32'hA5A5A5A5)(
    input [31:0] key,
    input [4:0] addr,
    output reg [127:0] data
);
    reg [127:0] encrypted [0:31];
    
    // Initialize memory with some encrypted values
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            // Use Kogge-Stone adder for calculation
            reg [127:0] base_value = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h87654321};
            reg [127:0] i_extended = {96'h0, i[31:0]};
            encrypted[i] = kogge_stone_adder(base_value, {i_extended, i_extended, i_extended, i_extended}) ^ {i, i, i, i};
        end
    end
    
    always @(*) begin
        data = (key == KEY) ? encrypted[addr] : 128'h0;
    end
    
    // Kogge-Stone Adder function for 128-bit addition
    function [127:0] kogge_stone_adder;
        input [127:0] a, b;
        reg [127:0] p, g; // Propagate and generate signals
        reg [127:0] p_level [0:7]; // Log2(128) = 7 levels for a 128-bit adder
        reg [127:0] g_level [0:7];
        reg [127:0] sum;
        integer j, k;
        begin
            // Initialize p and g
            p = a ^ b;
            g = a & b;
            
            // Store the initial values
            p_level[0] = p;
            g_level[0] = g;
            
            // Kogge-Stone parallel prefix computation
            // Level 1: distance = 1
            for (j = 0; j < 127; j = j + 1) begin
                p_level[1][j+1] = p_level[0][j+1] & p_level[0][j];
                g_level[1][j+1] = (p_level[0][j+1] & g_level[0][j]) | g_level[0][j+1];
            end
            p_level[1][0] = p_level[0][0];
            g_level[1][0] = g_level[0][0];
            
            // Level 2: distance = 2
            for (j = 0; j < 126; j = j + 1) begin
                p_level[2][j+2] = p_level[1][j+2] & p_level[1][j];
                g_level[2][j+2] = (p_level[1][j+2] & g_level[1][j]) | g_level[1][j+2];
            end
            p_level[2][1:0] = p_level[1][1:0];
            g_level[2][1:0] = g_level[1][1:0];
            
            // Level 3: distance = 4
            for (j = 0; j < 124; j = j + 1) begin
                p_level[3][j+4] = p_level[2][j+4] & p_level[2][j];
                g_level[3][j+4] = (p_level[2][j+4] & g_level[2][j]) | g_level[2][j+4];
            end
            p_level[3][3:0] = p_level[2][3:0];
            g_level[3][3:0] = g_level[2][3:0];
            
            // Level 4: distance = 8
            for (j = 0; j < 120; j = j + 1) begin
                p_level[4][j+8] = p_level[3][j+8] & p_level[3][j];
                g_level[4][j+8] = (p_level[3][j+8] & g_level[3][j]) | g_level[3][j+8];
            end
            p_level[4][7:0] = p_level[3][7:0];
            g_level[4][7:0] = g_level[3][7:0];
            
            // Level 5: distance = 16
            for (j = 0; j < 112; j = j + 1) begin
                p_level[5][j+16] = p_level[4][j+16] & p_level[4][j];
                g_level[5][j+16] = (p_level[4][j+16] & g_level[4][j]) | g_level[4][j+16];
            end
            p_level[5][15:0] = p_level[4][15:0];
            g_level[5][15:0] = g_level[4][15:0];
            
            // Level 6: distance = 32
            for (j = 0; j < 96; j = j + 1) begin
                p_level[6][j+32] = p_level[5][j+32] & p_level[5][j];
                g_level[6][j+32] = (p_level[5][j+32] & g_level[5][j]) | g_level[5][j+32];
            end
            p_level[6][31:0] = p_level[5][31:0];
            g_level[6][31:0] = g_level[5][31:0];
            
            // Level 7: distance = 64
            for (j = 0; j < 64; j = j + 1) begin
                p_level[7][j+64] = p_level[6][j+64] & p_level[6][j];
                g_level[7][j+64] = (p_level[6][j+64] & g_level[6][j]) | g_level[6][j+64];
            end
            p_level[7][63:0] = p_level[6][63:0];
            g_level[7][63:0] = g_level[6][63:0];
            
            // Compute sum
            sum[0] = p[0] ^ 1'b0; // No carry-in
            for (k = 1; k < 128; k = k + 1) begin
                sum[k] = p[k] ^ g_level[7][k-1];
            end
            
            kogge_stone_adder = sum;
        end
    endfunction
endmodule