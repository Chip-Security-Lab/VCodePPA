module serial_adder (
    input clk,
    input [7:0] a,
    input [7:0] b, 
    output reg [7:0] sum
);

    // Brent-Kung adder signals
    wire [7:0] g, p;
    reg [7:0] g_reg, p_reg;
    wire [7:0] g2, p2;
    reg [7:0] g2_reg, p2_reg;
    wire [7:0] g4, p4;
    reg [7:0] g4_reg, p4_reg;
    wire [7:0] g8, p8;
    wire [7:0] c;
    
    // Generate and propagate with buffer
    assign g = a & b;
    assign p = a ^ b;
    
    always @(posedge clk) begin
        g_reg <= g;
        p_reg <= p;
    end
    
    // First level with buffer
    assign g2[0] = g_reg[0];
    assign p2[0] = p_reg[0];
    assign g2[1] = g_reg[1] | (p_reg[1] & g_reg[0]);
    assign p2[1] = p_reg[1] & p_reg[0];
    
    always @(posedge clk) begin
        g2_reg <= g2;
        p2_reg <= p2;
    end
    
    // Second level with buffer
    assign g4[0] = g2_reg[0];
    assign p4[0] = p2_reg[0];
    assign g4[1] = g2_reg[1];
    assign p4[1] = p2_reg[1];
    assign g4[2] = g2_reg[2] | (p2_reg[2] & g2_reg[0]);
    assign p4[2] = p2_reg[2] & p2_reg[0];
    assign g4[3] = g2_reg[3] | (p2_reg[3] & g2_reg[1]);
    assign p4[3] = p2_reg[3] & p2_reg[1];
    
    always @(posedge clk) begin
        g4_reg <= g4;
        p4_reg <= p4;
    end
    
    // Third level
    assign g8[0] = g4_reg[0];
    assign p8[0] = p4_reg[0];
    assign g8[1] = g4_reg[1];
    assign p8[1] = p4_reg[1];
    assign g8[2] = g4_reg[2];
    assign p8[2] = p4_reg[2];
    assign g8[3] = g4_reg[3];
    assign p8[3] = p4_reg[3];
    assign g8[4] = g4_reg[4] | (p4_reg[4] & g4_reg[0]);
    assign p8[4] = p4_reg[4] & p4_reg[0];
    assign g8[5] = g4_reg[5] | (p4_reg[5] & g4_reg[1]);
    assign p8[5] = p4_reg[5] & p4_reg[1];
    assign g8[6] = g4_reg[6] | (p4_reg[6] & g4_reg[2]);
    assign p8[6] = p4_reg[6] & p4_reg[2];
    assign g8[7] = g4_reg[7] | (p4_reg[7] & g4_reg[3]);
    assign p8[7] = p4_reg[7] & p4_reg[3];
    
    // Carry computation
    assign c[0] = 1'b0;
    assign c[1] = g8[0];
    assign c[2] = g8[1];
    assign c[3] = g8[2];
    assign c[4] = g8[3];
    assign c[5] = g8[4];
    assign c[6] = g8[5];
    assign c[7] = g8[6];
    
    // Sum computation
    always @(posedge clk) begin
        sum <= p_reg ^ c;
    end

endmodule