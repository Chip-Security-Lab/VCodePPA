//SystemVerilog
module sync_decim_filter #(
    parameter WIDTH = 8,
    parameter RATIO = 4
)(
    input clock, reset,
    input [WIDTH-1:0] in_data,
    input in_valid,
    output reg [WIDTH-1:0] out_data,
    output reg out_valid
);
    // Pipeline stage 1: Counter and initial accumulation
    reg [$clog2(RATIO)-1:0] counter_stage1;
    reg [WIDTH-1:0] sum_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Accumulation and counter update
    reg [$clog2(RATIO)-1:0] counter_stage2;
    reg [WIDTH-1:0] sum_stage2;
    reg [WIDTH-1:0] in_data_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3: Final accumulation and division
    reg [WIDTH-1:0] sum_stage3;
    reg valid_stage3;
    reg [WIDTH-1:0] temp_sum;
    
    // Stage 1: Initial processing
    always @(posedge clock) begin
        if (reset) begin
            counter_stage1 <= 0;
            sum_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            valid_stage1 <= in_valid;
            if (in_valid) begin
                sum_stage1 <= in_data;
                counter_stage1 <= 1;
            end else begin
                sum_stage1 <= 0;
                counter_stage1 <= 0;
            end
        end
    end
    
    // Stage 2: Accumulation and counter update
    always @(posedge clock) begin
        if (reset) begin
            counter_stage2 <= 0;
            sum_stage2 <= 0;
            in_data_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            in_data_stage2 <= in_data;
            
            if (valid_stage1) begin
                if (counter_stage1 == RATIO-1) begin
                    counter_stage2 <= 0;
                    sum_stage2 <= sum_stage1;
                end else begin
                    counter_stage2 <= counter_stage1 + 1;
                    sum_stage2 <= sum_stage1;
                end
            end else begin
                counter_stage2 <= 0;
                sum_stage2 <= 0;
            end
        end
    end
    
    // Stage 3: Final accumulation and division
    always @(posedge clock) begin
        if (reset) begin
            sum_stage3 <= 0;
            valid_stage3 <= 0;
            temp_sum <= 0;
        end else begin
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2) begin
                if (counter_stage2 == 0) begin
                    sum_stage3 <= in_data_stage2;
                end else begin
                    sum_stage3 <= sum_stage2 + in_data_stage2;
                end
                
                if (counter_stage2 == RATIO-1) begin
                    temp_sum <= sum_stage2 + in_data_stage2;
                end
            end else begin
                sum_stage3 <= 0;
                temp_sum <= 0;
            end
        end
    end
    
    // Output stage
    always @(posedge clock) begin
        if (reset) begin
            out_data <= 0;
            out_valid <= 0;
        end else begin
            if (valid_stage3 && counter_stage2 == RATIO-1) begin
                out_data <= temp_sum / RATIO;
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end
endmodule