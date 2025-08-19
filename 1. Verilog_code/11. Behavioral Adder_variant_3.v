module behavioral_adder(
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] sum,
    output reg cout
);

    // Stage 1: Generate and Propagate
    reg [7:0] g, p;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g <= 8'b0;
            p <= 8'b0;
        end else begin
            g <= a & b;
            p <= a ^ b;
        end
    end

    // Stage 2: Group Generate and Propagate
    reg [1:0] g0, p0, g1, p1, g2, p2, g3, p3;
    reg G0, P0, G1, P1, G2, P2, G3, P3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            g0 <= 2'b0; p0 <= 2'b0;
            g1 <= 2'b0; p1 <= 2'b0;
            g2 <= 2'b0; p2 <= 2'b0;
            g3 <= 2'b0; p3 <= 2'b0;
            G0 <= 1'b0; P0 <= 1'b0;
            G1 <= 1'b0; P1 <= 1'b0;
            G2 <= 1'b0; P2 <= 1'b0;
            G3 <= 1'b0; P3 <= 1'b0;
        end else begin
            g0 <= g[1:0]; p0 <= p[1:0];
            g1 <= g[3:2]; p1 <= p[3:2];
            g2 <= g[5:4]; p2 <= p[5:4];
            g3 <= g[7:6]; p3 <= p[7:6];
            
            G0 <= g0[1] | (p0[1] & g0[0]);
            P0 <= p0[1] & p0[0];
            G1 <= g1[1] | (p1[1] & g1[0]);
            P1 <= p1[1] & p1[0];
            G2 <= g2[1] | (p2[1] & g2[0]);
            P2 <= p2[1] & p2[0];
            G3 <= g3[1] | (p3[1] & g3[0]);
            P3 <= p3[1] & p3[0];
        end
    end

    // Stage 3: Carry Generation
    reg [8:0] c;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c <= 9'b0;
        end else begin
            c[0] <= 1'b0;
            c[2] <= G0 | (P0 & c[0]);
            c[4] <= G1 | (P1 & G0) | (P1 & P0 & c[0]);
            c[6] <= G2 | (P2 & G1) | (P2 & P1 & G0) | (P2 & P1 & P0 & c[0]);
            c[8] <= G3 | (P3 & G2) | (P3 & P2 & G1) | (P3 & P2 & P1 & G0) | (P3 & P2 & P1 & P0 & c[0]);
            
            c[1] <= g0[0] | (p0[0] & c[0]);
            c[3] <= g1[0] | (p1[0] & c[2]);
            c[5] <= g2[0] | (p2[0] & c[4]);
            c[7] <= g3[0] | (p3[0] & c[6]);
        end
    end

    // Stage 4: Sum and Carry Out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 8'b0;
            cout <= 1'b0;
        end else begin
            sum <= p ^ c[7:0];
            cout <= c[8];
        end
    end

endmodule