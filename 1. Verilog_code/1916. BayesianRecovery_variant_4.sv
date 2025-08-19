//SystemVerilog
module BayesianRecovery #(parameter WIDTH=8, HIST_DEPTH=4) (
    input clk,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] restored
);
    reg [WIDTH-1:0] history [0:HIST_DEPTH-1];
    reg [WIDTH+2:0] sum_stage1;
    reg [WIDTH+2:0] sum_stage2;
    reg [WIDTH+2:0] prob_sum_pipeline;
    reg [WIDTH+1:0] threshold_pipeline;
    integer i;

    // History update
    always @(posedge clk) begin : history_update
        for (i = HIST_DEPTH-1; i > 0; i = i - 1) begin
            history[i] <= history[i-1];
        end
        history[0] <= noisy_in;
    end

    // Pipeline stage 1: pairwise addition
    always @(posedge clk) begin : pipeline_stage1
        sum_stage1 <= history[0] + history[1];
        sum_stage2 <= history[2] + history[3];
    end

    // Pipeline stage 2: final sum and threshold calculation
    always @(posedge clk) begin : pipeline_stage2
        prob_sum_pipeline <= sum_stage1 + sum_stage2;
        threshold_pipeline <= (1 << (WIDTH+1));
    end

    // Output register stage with if-else replacing conditional operator
    always @(posedge clk) begin : output_stage
        if (prob_sum_pipeline > threshold_pipeline) begin
            restored <= {WIDTH{1'b1}};
        end else begin
            restored <= {WIDTH{1'b0}};
        end
    end

endmodule