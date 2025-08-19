//SystemVerilog
module counter_dual_edge #(parameter WIDTH=4) (
    input clk, rst,
    output reg [WIDTH:0] cnt
);
    // Stage 1 registers - capture counters with reduced bit width
    reg [WIDTH-1:0] pos_cnt_stage1;
    reg [WIDTH-1:0] neg_cnt_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - optimized pipeline
    reg [WIDTH-1:0] pos_cnt_stage2;
    reg [WIDTH-1:0] neg_cnt_stage2;
    reg valid_stage2;
    
    // Stage 3 registers - result
    reg [WIDTH:0] sum_stage3;
    reg valid_stage3;
    
    // Optimized posedge counter with single valid transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_cnt_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            pos_cnt_stage1 <= pos_cnt_stage1 + 1'b1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Optimized negedge counter
    reg neg_valid;
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            neg_cnt_stage1 <= {WIDTH{1'b0}};
            neg_valid <= 1'b0;
        end
        else begin
            neg_cnt_stage1 <= neg_cnt_stage1 + 1'b1;
            neg_valid <= 1'b1;
        end
    end
    
    // Optimized Stage 2 - Pre-computed valid condition
    wire stage2_valid = valid_stage1 & neg_valid;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pos_cnt_stage2 <= {WIDTH{1'b0}};
            neg_cnt_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            pos_cnt_stage2 <= pos_cnt_stage1;
            neg_cnt_stage2 <= neg_cnt_stage1;
            valid_stage2 <= stage2_valid;
        end
    end
    
    // Optimized Stage 3 - Addition with pre-computed sum
    wire [WIDTH:0] addition_result = {1'b0, pos_cnt_stage2} + {1'b0, neg_cnt_stage2};
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum_stage3 <= {(WIDTH+1){1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            sum_stage3 <= addition_result;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Optimized Output assignment with single cycle enable logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= {(WIDTH+1){1'b0}};
        end
        else if (valid_stage3) begin
            cnt <= sum_stage3;
        end
    end
endmodule