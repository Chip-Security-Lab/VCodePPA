//SystemVerilog
module dram_ctrl_power #(
    parameter LOW_POWER_THRESH = 100
)(
    input clk,
    input activity,
    output reg clk_en
);
    reg [7:0] idle_counter;
    wire counter_lt_thresh;
    
    // Kogge-Stone adder signals
    wire [7:0] g, p;
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;
    wire [7:0] g3, p3;
    wire [7:0] sum;
    
    // Generate and Propagate
    assign g = idle_counter & 8'd1;
    assign p = idle_counter ^ 8'd1;
    
    // First stage
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    assign g1[4] = g[4] | (p[4] & g[3]);
    assign p1[4] = p[4] & p[3];
    assign g1[5] = g[5] | (p[5] & g[4]);
    assign p1[5] = p[5] & p[4];
    assign g1[6] = g[6] | (p[6] & g[5]);
    assign p1[6] = p[6] & p[5];
    assign g1[7] = g[7] | (p[7] & g[6]);
    assign p1[7] = p[7] & p[6];
    
    // Second stage
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    assign g2[4] = g1[4] | (p1[4] & g1[2]);
    assign p2[4] = p1[4] & p1[2];
    assign g2[5] = g1[5] | (p1[5] & g1[3]);
    assign p2[5] = p1[5] & p1[3];
    assign g2[6] = g1[6] | (p1[6] & g1[4]);
    assign p2[6] = p1[6] & p1[4];
    assign g2[7] = g1[7] | (p1[7] & g1[5]);
    assign p2[7] = p1[7] & p1[5];
    
    // Third stage
    assign g3[0] = g2[0];
    assign p3[0] = p2[0];
    assign g3[1] = g2[1];
    assign p3[1] = p2[1];
    assign g3[2] = g2[2];
    assign p3[2] = p2[2];
    assign g3[3] = g2[3];
    assign p3[3] = p2[3];
    assign g3[4] = g2[4] | (p2[4] & g2[0]);
    assign p3[4] = p2[4] & p2[0];
    assign g3[5] = g2[5] | (p2[5] & g2[1]);
    assign p3[5] = p2[5] & p2[1];
    assign g3[6] = g2[6] | (p2[6] & g2[2]);
    assign p3[6] = p2[6] & p2[2];
    assign g3[7] = g2[7] | (p2[7] & g2[3]);
    assign p3[7] = p2[7] & p2[3];
    
    // Final sum calculation
    assign sum[0] = p[0];
    assign sum[1] = p[1] ^ g3[0];
    assign sum[2] = p[2] ^ g3[1];
    assign sum[3] = p[3] ^ g3[2];
    assign sum[4] = p[4] ^ g3[3];
    assign sum[5] = p[5] ^ g3[4];
    assign sum[6] = p[6] ^ g3[5];
    assign sum[7] = p[7] ^ g3[6];
    
    assign counter_lt_thresh = (idle_counter < LOW_POWER_THRESH);
    
    always @(posedge clk) begin
        if(activity) begin
            idle_counter <= 8'd0;
            clk_en <= 1'b1;
        end else begin
            idle_counter <= counter_lt_thresh ? sum : idle_counter;
            clk_en <= counter_lt_thresh;
        end
    end
endmodule