//SystemVerilog
module ITRC_PulseCounter #(
    parameter WIDTH = 8,
    parameter THRESHOLD = 5
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg int_out
);

    // Pipeline stage 1 registers
    reg [3:0] counters_stage1 [0:WIDTH-1];
    reg [WIDTH-1:0] int_in_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] threshold_met_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [WIDTH-1:0] threshold_met_buf_stage3;
    reg valid_stage3;
    
    genvar i;
    integer j;
    
    // Stage 1: Counter logic
    generate
        for (i=0; i<WIDTH; i=i+1) begin : gen_counter
            always @(posedge clk) begin
                if (!rst_n) begin
                    counters_stage1[i] <= 0;
                end
                else if (int_in[i]) begin
                    counters_stage1[i] <= (counters_stage1[i] < THRESHOLD) ? 
                                        counters_stage1[i] + 1 : counters_stage1[i];
                end
                else begin
                    counters_stage1[i] <= 0;
                end
            end
        end
    endgenerate
    
    // Stage 1: Input buffering
    always @(posedge clk) begin
        if (!rst_n) begin
            int_in_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            int_in_stage1 <= int_in;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Threshold detection
    always @(posedge clk) begin
        if (!rst_n) begin
            threshold_met_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else begin
            for (j=0; j<WIDTH; j=j+1) begin
                threshold_met_stage2[j] <= (counters_stage1[j] >= THRESHOLD);
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Buffer registers
    always @(posedge clk) begin
        if (!rst_n) begin
            threshold_met_buf_stage3 <= 0;
            valid_stage3 <= 0;
        end
        else begin
            threshold_met_buf_stage3 <= threshold_met_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Final stage: OR reduction
    always @(posedge clk) begin
        if (!rst_n) begin
            int_out <= 0;
        end
        else begin
            int_out <= valid_stage3 ? |threshold_met_buf_stage3 : 0;
        end
    end

endmodule