module predictive_encoder #(
    parameter DATA_WIDTH = 12
)(
    input                     clk,
    input                     reset,
    input [DATA_WIDTH-1:0]    sample_in,
    input                     in_valid,
    output reg [DATA_WIDTH-1:0] residual_out,
    output reg                out_valid
);
    reg [DATA_WIDTH-1:0] prev_samples [0:3];
    reg [DATA_WIDTH-1:0] prediction;
    reg [DATA_WIDTH+1:0] sum_temp; // 额外位宽处理加法
    integer i;
    
    // Prediction function - average of previous samples
    always @(*) begin
        sum_temp = 0;
        for (i = 0; i < 4; i = i + 1)
            sum_temp = sum_temp + prev_samples[i];
        prediction = sum_temp >> 2;
    end
    
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1)
                prev_samples[i] <= 0;
            out_valid <= 0;
            residual_out <= 0;
        end else if (in_valid) begin
            // Calculate residual (difference from prediction)
            // 手动处理有符号数减法
            if (sample_in >= prediction)
                residual_out <= sample_in - prediction;
            else
                residual_out <= (~(prediction - sample_in) + 1) & ((1 << DATA_WIDTH) - 1);
            
            // Update sample history
            prev_samples[3] <= prev_samples[2];
            prev_samples[2] <= prev_samples[1];
            prev_samples[1] <= prev_samples[0];
            prev_samples[0] <= sample_in;
            
            out_valid <= 1;
        end else begin
            out_valid <= 0;
        end
    end
endmodule