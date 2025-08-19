//SystemVerilog
module brent_kung_adder(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire [15:0] sum,
    output wire cout
);
    wire [15:0] p, g;
    wire [7:0] p1, g1;
    wire [3:0] p2, g2;
    wire [1:0] p3, g3;
    wire p4, g4;
    
    // Pre-computation
    assign p = a ^ b;
    assign g = a & b;
    
    // First level
    assign p1[0] = p[0] & p[1];
    assign g1[0] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[2] & p[3];
    assign g1[1] = g[3] | (p[3] & g[2]);
    assign p1[2] = p[4] & p[5];
    assign g1[2] = g[5] | (p[5] & g[4]);
    assign p1[3] = p[6] & p[7];
    assign g1[3] = g[7] | (p[7] & g[6]);
    assign p1[4] = p[8] & p[9];
    assign g1[4] = g[9] | (p[9] & g[8]);
    assign p1[5] = p[10] & p[11];
    assign g1[5] = g[11] | (p[11] & g[10]);
    assign p1[6] = p[12] & p[13];
    assign g1[6] = g[13] | (p[13] & g[12]);
    assign p1[7] = p[14] & p[15];
    assign g1[7] = g[15] | (p[15] & g[14]);
    
    // Second level
    assign p2[0] = p1[0] & p1[1];
    assign g2[0] = g1[1] | (p1[1] & g1[0]);
    assign p2[1] = p1[2] & p1[3];
    assign g2[1] = g1[3] | (p1[3] & g1[2]);
    assign p2[2] = p1[4] & p1[5];
    assign g2[2] = g1[5] | (p1[5] & g1[4]);
    assign p2[3] = p1[6] & p1[7];
    assign g2[3] = g1[7] | (p1[7] & g1[6]);
    
    // Third level
    assign p3[0] = p2[0] & p2[1];
    assign g3[0] = g2[1] | (p2[1] & g2[0]);
    assign p3[1] = p2[2] & p2[3];
    assign g3[1] = g2[3] | (p2[3] & g2[2]);
    
    // Fourth level
    assign p4 = p3[0] & p3[1];
    assign g4 = g3[1] | (p3[1] & g3[0]);
    
    // Carry computation
    wire [15:0] c;
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & cin);
    assign c[2] = g1[0] | (p1[0] & cin);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g2[0] | (p2[0] & cin);
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g1[2] | (p1[2] & c[4]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g3[0] | (p3[0] & cin);
    assign c[9] = g[8] | (p[8] & c[8]);
    assign c[10] = g1[4] | (p1[4] & c[8]);
    assign c[11] = g[10] | (p[10] & c[10]);
    assign c[12] = g2[2] | (p2[2] & c[8]);
    assign c[13] = g[12] | (p[12] & c[12]);
    assign c[14] = g1[6] | (p1[6] & c[12]);
    assign c[15] = g[14] | (p[14] & c[14]);
    
    // Sum computation
    assign sum = p ^ c;
    assign cout = g4 | (p4 & cin);
endmodule

module priority_range_detector(
    input wire clk, rst_n,
    input wire [15:0] value,
    input wire [15:0] range_start [0:3],
    input wire [15:0] range_end [0:3],
    output reg [2:0] range_id,
    output reg valid
);
    wire [15:0] range_start_comp [0:3];
    wire [15:0] range_end_comp [0:3];
    wire [3:0] in_range;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : range_comparison
            brent_kung_adder start_comp(
                .a(value),
                .b(~range_start[i]),
                .cin(1'b1),
                .sum(range_start_comp[i]),
                .cout()
            );
            
            brent_kung_adder end_comp(
                .a(range_end[i]),
                .b(~value),
                .cin(1'b1),
                .sum(range_end_comp[i]),
                .cout()
            );
            
            assign in_range[i] = ~range_start_comp[i][15] & ~range_end_comp[i][15];
        end
    endgenerate
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            range_id <= 3'd0;
            valid <= 1'b0;
        end
        else begin
            valid <= 1'b0;
            casez (in_range)
                4'b???1: begin range_id <= 0; valid <= 1'b1; end
                4'b??10: begin range_id <= 1; valid <= 1'b1; end
                4'b?100: begin range_id <= 2; valid <= 1'b1; end
                4'b1000: begin range_id <= 3; valid <= 1'b1; end
                default: begin range_id <= range_id; valid <= 1'b0; end
            endcase
        end
    end
endmodule