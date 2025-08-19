//SystemVerilog
module quadrature_sine(
    input clk,
    input reset,
    input req,                // Request signal (replacing implicit valid)
    input [7:0] freq_ctrl,    // Frequency control input
    output reg [7:0] sine,    // Sine output
    output reg [7:0] cosine,  // Cosine output
    output reg ack            // Acknowledge signal (replacing implicit ready)
);
    // Phase registers with buffering
    reg [7:0] phase;
    reg [7:0] phase_buf;
    
    // LUT with buffered outputs
    reg [7:0] sin_lut [0:7];
    reg [7:0] sin_lut_buf [0:7];
    
    // Request signal buffering
    reg req_r1;
    reg req_r2;
    
    // Phase index buffering
    reg [2:0] phase_idx;
    reg [2:0] phase_idx_buf;
    
    initial begin
        sin_lut[0] = 8'd128; sin_lut[1] = 8'd218;
        sin_lut[2] = 8'd255; sin_lut[3] = 8'd218;
        sin_lut[4] = 8'd128; sin_lut[5] = 8'd37;
        sin_lut[6] = 8'd0;   sin_lut[7] = 8'd37;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            phase <= 8'd0;
            phase_buf <= 8'd0;
            sine <= 8'd128;
            cosine <= 8'd255;
            ack <= 1'b0;
            req_r1 <= 1'b0;
            req_r2 <= 1'b0;
            phase_idx <= 3'd0;
            phase_idx_buf <= 3'd0;
        end else begin
            // Two-stage request buffering
            req_r1 <= req;
            req_r2 <= req_r1;
            
            // Phase calculation with buffering
            if (req && !req_r2) begin
                phase <= phase + freq_ctrl;
                phase_buf <= phase;
                phase_idx <= phase[7:5];
                phase_idx_buf <= phase_idx;
            end
            
            // LUT output buffering
            sin_lut_buf[0] <= sin_lut[0];
            sin_lut_buf[1] <= sin_lut[1];
            sin_lut_buf[2] <= sin_lut[2];
            sin_lut_buf[3] <= sin_lut[3];
            sin_lut_buf[4] <= sin_lut[4];
            sin_lut_buf[5] <= sin_lut[5];
            sin_lut_buf[6] <= sin_lut[6];
            sin_lut_buf[7] <= sin_lut[7];
            
            // Output generation with buffered signals
            if (req && !req_r2) begin
                sine <= sin_lut_buf[phase_idx_buf];
                cosine <= sin_lut_buf[(phase_idx_buf + 3'd2) % 8];
                ack <= 1'b1;
            end else if (!req && req_r2) begin
                ack <= 1'b0;
            end
        end
    end
endmodule