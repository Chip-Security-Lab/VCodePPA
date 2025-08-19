//SystemVerilog
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
module predictive_encoder #(
    parameter DATA_WIDTH = 12
)(
    input                       clk,
    input                       reset,
    input [DATA_WIDTH-1:0]      sample_in,
    input                       in_valid,
    output reg [DATA_WIDTH-1:0] residual_out,
    output reg                  out_valid
);
    // Previous samples storage
    reg [DATA_WIDTH-1:0] prev_samples [0:3];
    
    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] sample_stage1, sample_stage2;
    reg [DATA_WIDTH-1:0] prediction_stage1, prediction_stage2;
    reg                  valid_stage1, valid_stage2;
    
    // Temporary calculation signals
    wire [DATA_WIDTH+1:0] sum_temp; // Extra width for addition
    integer i;
    
    //////////////////////////////////////////////////////////////////////////////
    // Sample history shift register
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1)
                prev_samples[i] <= 0;
        end
        else if (in_valid) begin
            prev_samples[3] <= prev_samples[2];
            prev_samples[2] <= prev_samples[1];
            prev_samples[1] <= prev_samples[0];
            prev_samples[0] <= sample_in;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Prediction calculation logic
    //////////////////////////////////////////////////////////////////////////////
    assign sum_temp = prev_samples[0] + prev_samples[1] + prev_samples[2] + prev_samples[3];
    
    //////////////////////////////////////////////////////////////////////////////
    // Pipeline stage 1: Input registration and prediction
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            sample_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            sample_stage1 <= sample_in;
            valid_stage1 <= in_valid;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            prediction_stage1 <= 0;
        end
        else begin
            prediction_stage1 <= sum_temp >> 2;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Pipeline stage 2: Forward values to next stage
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            sample_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            sample_stage2 <= sample_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    always @(posedge clk) begin
        if (reset) begin
            prediction_stage2 <= 0;
        end
        else begin
            prediction_stage2 <= prediction_stage1;
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Pipeline stage 3: Residual calculation
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            residual_out <= 0;
        end
        else if (valid_stage2) begin
            // Handle signed subtraction
            if (sample_stage2 >= prediction_stage2)
                residual_out <= sample_stage2 - prediction_stage2;
            else
                residual_out <= (~(prediction_stage2 - sample_stage2) + 1) & ((1 << DATA_WIDTH) - 1);
        end
    end
    
    //////////////////////////////////////////////////////////////////////////////
    // Output valid signal generation
    //////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (reset) begin
            out_valid <= 0;
        end
        else begin
            out_valid <= valid_stage2;
        end
    end
    
endmodule