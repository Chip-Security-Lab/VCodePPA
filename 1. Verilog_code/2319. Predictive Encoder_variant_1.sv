//SystemVerilog

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
    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] sample_in_reg;
    reg                  valid_stage1;
    reg                  valid_stage2;
    
    // History buffer
    reg [DATA_WIDTH-1:0] sample_history [0:3];
    
    // Prediction datapath signals
    wire [DATA_WIDTH-1:0] adder_inputs [0:3];
    wire [DATA_WIDTH+1:0] prediction_sum;
    reg  [DATA_WIDTH-1:0] prediction_reg;
    
    // Residual calculation signals
    wire [DATA_WIDTH-1:0] sample_for_residual;
    wire [DATA_WIDTH-1:0] prediction_for_residual;
    wire [DATA_WIDTH-1:0] residual_result;
    wire                  is_negative;
    
    // Input stage: register inputs and update history
    always @(posedge clk) begin
        if (reset) begin
            sample_in_reg <= 0;
            valid_stage1 <= 0;
        end else begin
            sample_in_reg <= sample_in;
            valid_stage1 <= in_valid;
        end
    end
    
    // Sample history management
    always @(posedge clk) begin
        if (reset) begin
            sample_history[0] <= 0;
            sample_history[1] <= 0;
            sample_history[2] <= 0;
            sample_history[3] <= 0;
        end else if (in_valid) begin
            sample_history[3] <= sample_history[2];
            sample_history[2] <= sample_history[1];
            sample_history[1] <= sample_history[0];
            sample_history[0] <= sample_in;
        end
    end
    
    // Connect history samples to adder inputs
    assign adder_inputs[0] = sample_history[0];
    assign adder_inputs[1] = sample_history[1];
    assign adder_inputs[2] = sample_history[2];
    assign adder_inputs[3] = sample_history[3];
    
    // Prediction calculation datapath
    optimized_prefix_adder #(
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_INPUTS(4)
    ) predictor_adder (
        .clk(clk),
        .reset(reset),
        .enable(valid_stage1),
        .operands_in({adder_inputs[3], adder_inputs[2], adder_inputs[1], adder_inputs[0]}),
        .sum_out(prediction_sum)
    );
    
    // Register prediction result and control
    always @(posedge clk) begin
        if (reset) begin
            prediction_reg <= 0;
            valid_stage2 <= 0;
        end else begin
            prediction_reg <= prediction_sum[DATA_WIDTH+1:2]; // Divide by 4
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Residual calculation (data path)
    assign sample_for_residual = sample_in_reg;
    assign prediction_for_residual = prediction_reg;
    assign is_negative = sample_for_residual < prediction_for_residual;
    assign residual_result = is_negative ? 
                            ((~(prediction_for_residual - sample_for_residual) + 1) & ((1 << DATA_WIDTH) - 1)) : 
                            (sample_for_residual - prediction_for_residual);
    
    // Output stage
    always @(posedge clk) begin
        if (reset) begin
            residual_out <= 0;
            out_valid <= 0;
        end else begin
            residual_out <= residual_result;
            out_valid <= valid_stage2;
        end
    end
endmodule

module optimized_prefix_adder #(
    parameter DATA_WIDTH = 12,
    parameter NUM_INPUTS = 4
)(
    input                             clk,
    input                             reset,
    input                             enable,
    input [(NUM_INPUTS*DATA_WIDTH)-1:0] operands_in,
    output reg [DATA_WIDTH+1:0]       sum_out
);
    // Input stage registers
    reg [(NUM_INPUTS*DATA_WIDTH)-1:0] operands_reg;
    
    // Intermediate stage signals
    wire [DATA_WIDTH-1:0] inputs [0:NUM_INPUTS-1];
    wire [DATA_WIDTH:0] stage1 [0:NUM_INPUTS-1];
    reg [DATA_WIDTH:0] stage1_reg [0:NUM_INPUTS-1];
    wire [DATA_WIDTH+1:0] stage2 [0:NUM_INPUTS-1];
    
    // Register inputs
    always @(posedge clk) begin
        if (reset) begin
            operands_reg <= 0;
        end else if (enable) begin
            operands_reg <= operands_in;
        end
    end
    
    // Unpack input operands
    genvar j;
    generate
        for (j = 0; j < NUM_INPUTS; j = j + 1) begin: gen_input
            assign inputs[j] = operands_reg[(j+1)*DATA_WIDTH-1:j*DATA_WIDTH];
        end
    endgenerate
    
    // Stage 1: Prepare operands with sign extension
    genvar i;
    generate
        for (i = 0; i < NUM_INPUTS; i = i + 1) begin: gen_stage1
            assign stage1[i] = {1'b0, inputs[i]};
        end
    endgenerate
    
    // Register stage 1 outputs
    integer k;
    always @(posedge clk) begin
        if (reset) begin
            for (k = 0; k < NUM_INPUTS; k = k + 1) begin
                stage1_reg[k] <= 0;
            end
        end else if (enable) begin
            for (k = 0; k < NUM_INPUTS; k = k + 1) begin
                stage1_reg[k] <= stage1[k];
            end
        end
    end
    
    // Stage 2: Parallel prefix tree (optimized Kogge-Stone layout)
    // First path - direct connection
    assign stage2[0] = {1'b0, stage1_reg[0]};
    
    // Partial sum paths with balanced tree structure
    assign stage2[1] = {1'b0, stage1_reg[0]} + {1'b0, stage1_reg[1]};
    assign stage2[2] = {1'b0, stage1_reg[0]} + {1'b0, stage1_reg[1]} + {1'b0, stage1_reg[2]};
    assign stage2[3] = {1'b0, stage1_reg[0]} + {1'b0, stage1_reg[1]} + {1'b0, stage1_reg[2]} + {1'b0, stage1_reg[3]};
    
    // Register final result
    always @(posedge clk) begin
        if (reset) begin
            sum_out <= 0;
        end else if (enable) begin
            sum_out <= stage2[NUM_INPUTS-1];
        end
    end
endmodule