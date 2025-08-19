//SystemVerilog IEEE 1364-2005
// Top level module
module Timer_MultiMode #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] period,
    output reg out
);
    // Internal connections and pipeline registers
    wire [7:0] counter_value;
    wire [7:0] buffered_count1, buffered_count2;
    
    // Pipeline control signals
    reg [2:0] valid_stage1, valid_stage2, valid_stage3;
    
    // Period register pipeline
    reg [7:0] period_stage1, period_stage2, period_stage3;
    
    // Counter submodule
    Counter counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count(counter_value)
    );
    
    // Buffer submodule with increased pipeline
    CountBuffer buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count_in(counter_value),
        .count_buf1(buffered_count1),
        .count_buf2(buffered_count2)
    );
    
    // Pipeline period input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_stage1 <= 8'h0;
            period_stage2 <= 8'h0;
            period_stage3 <= 8'h0;
        end
        else begin
            period_stage1 <= period;
            period_stage2 <= period_stage1;
            period_stage3 <= period_stage2;
        end
    end
    
    // Pipeline validity tracking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 3'b0;
            valid_stage2 <= 3'b0;
            valid_stage3 <= 3'b0;
        end
        else begin
            valid_stage1 <= 3'b111;
            valid_stage2 <= valid_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output logic submodule with deeper pipeline
    OutputController #(.MODE(MODE)) output_ctrl_inst (
        .clk(clk),
        .rst_n(rst_n),
        .count_buf1(buffered_count1),
        .count_buf2(buffered_count2),
        .period(period_stage3),
        .valid(valid_stage3),
        .out(out)
    );
endmodule

//SystemVerilog IEEE 1364-2005
// Enhanced pipelined counter submodule
module Counter (
    input clk, rst_n,
    output reg [7:0] count
);
    reg [7:0] next_count;
    
    // Pre-compute next count value
    always @(*) begin
        next_count = count + 8'h1;
    end
    
    // Register update with pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 8'h0;
        end
        else begin
            count <= next_count;
        end
    end
endmodule

//SystemVerilog IEEE 1364-2005
// Counter buffer with deeper pipeline
module CountBuffer (
    input clk, rst_n,
    input [7:0] count_in,
    output reg [7:0] count_buf1, count_buf2
);
    reg [7:0] count_stage1, count_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= 8'h0;
            count_stage2 <= 8'h0;
            count_buf1 <= 8'h0;
            count_buf2 <= 8'h0;
        end
        else begin
            // Increased pipeline depth
            count_stage1 <= count_in;      // Stage 1
            count_stage2 <= count_stage1;  // Stage 2
            count_buf1 <= count_stage2;    // Output buffer 1
            count_buf2 <= count_stage2;    // Output buffer 2
        end
    end
endmodule

//SystemVerilog IEEE 1364-2005
// Mode-specific output controller with deeper pipeline
module OutputController #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] count_buf1, count_buf2,
    input [7:0] period,
    input [2:0] valid,
    output reg out
);
    // Comparison result registers
    reg comp_equal, comp_greater, comp_freq;
    reg comp_equal_d, comp_greater_d, comp_freq_d;
    
    // Mode selection pipeline
    reg out_pre;
    
    // First stage: Calculate comparisons
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_equal <= 1'b0;
            comp_greater <= 1'b0;
            comp_freq <= 1'b0;
        end
        else begin
            comp_equal <= (count_buf1 == period);
            comp_greater <= (count_buf1 >= period);
            comp_freq <= (count_buf2[3:0] == period[3:0]);
        end
    end
    
    // Second stage: Register comparison results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            comp_equal_d <= 1'b0;
            comp_greater_d <= 1'b0;
            comp_freq_d <= 1'b0;
        end
        else begin
            comp_equal_d <= comp_equal;
            comp_greater_d <= comp_greater;
            comp_freq_d <= comp_freq;
        end
    end
    
    // Third stage: Select mode output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_pre <= 1'b0;
        end
        else begin
            case(MODE)
                0: out_pre <= comp_equal_d;      // Single trigger mode
                1: out_pre <= comp_greater_d;    // Continuous high level mode
                2: out_pre <= comp_freq_d;       // Frequency division mode
                default: out_pre <= 1'b0;
            endcase
        end
    end
    
    // Final stage: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end
        else if (valid[0]) begin
            out <= out_pre;
        end
    end
endmodule