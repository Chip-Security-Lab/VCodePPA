//SystemVerilog
module quadrature_sine(
    input clk,
    input reset,
    input [7:0] freq_ctrl,
    output reg [7:0] sine,
    output reg [7:0] cosine
);
    reg [7:0] phase;
    reg [7:0] sin_lut [0:7];
    wire [2:0] sine_idx;
    wire [2:0] cosine_idx;
    wire [7:0] phase_next;
    
    // Kogge-Stone Adder implementation
    wire [7:0] g0, p0;
    wire [7:0] g1, p1;
    wire [7:0] g2, p2;
    wire [7:0] g3, p3;
    
    // Generate and Propagate signals
    assign g0 = phase & freq_ctrl;
    assign p0 = phase ^ freq_ctrl;
    
    // First level
    assign g1[0] = g0[0];
    assign p1[0] = p0[0];
    assign g1[1] = g0[1] | (p0[1] & g0[0]);
    assign p1[1] = p0[1] & p0[0];
    
    // Second level
    assign g2[1:0] = g1[1:0];
    assign p2[1:0] = p1[1:0];
    assign g2[3:2] = g1[3:2] | (p1[3:2] & g1[1:0]);
    assign p2[3:2] = p1[3:2] & p1[1:0];
    
    // Third level
    assign g3[3:0] = g2[3:0];
    assign p3[3:0] = p2[3:0];
    assign g3[7:4] = g2[7:4] | (p2[7:4] & g2[3:0]);
    assign p3[7:4] = p2[7:4] & p2[3:0];
    
    // Final sum calculation
    assign phase_next = p0 ^ {g3[6:0], 1'b0};
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd218;
        sin_lut[2] = 8'd255; sin_lut[3] = 8'd218;
        sin_lut[4] = 8'd128; sin_lut[5] = 8'd37;
        sin_lut[6] = 8'd0;   sin_lut[7] = 8'd37;
    end
    
    assign sine_idx = phase[7:5];
    assign cosine_idx = (sine_idx + 3'd2) & 3'b111;
    
    always @(posedge clk) begin
        if (reset) begin
            phase <= 8'd0;
            sine <= 8'd128;
            cosine <= 8'd255;
        end else begin
            phase <= phase_next;
            sine <= sin_lut[sine_idx];
            cosine <= sin_lut[cosine_idx];
        end
    end
endmodule