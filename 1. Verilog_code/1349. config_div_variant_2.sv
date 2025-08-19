//SystemVerilog
module config_div #(parameter MODE=0) (
    input wire clk, rst,
    output reg clk_out
);
    // Define divider value based on MODE parameter
    localparam DIV = (MODE) ? 8 : 16;
    // Calculate required counter width based on maximum DIV value
    localparam CNT_WIDTH = $clog2(DIV);
    
    // Use optimized counter width for each pipeline stage
    reg [CNT_WIDTH-1:0] cnt_stage1;
    reg [CNT_WIDTH-1:0] cnt_stage2;
    reg [CNT_WIDTH-1:0] cnt_stage3;
    reg [CNT_WIDTH-1:0] cnt_stage4;
    
    // Precompute terminal count for comparison
    localparam [CNT_WIDTH-1:0] TERMINAL_CNT = DIV - 1;
    
    // Pipeline control signals expanded for more stages
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg compare_result_stage1;
    reg terminal_reached_stage2, terminal_reached_stage3;
    
    // Intermediate comparison results for deeper pipeline
    reg [CNT_WIDTH/2-1:0] cnt_upper_stage1, cnt_upper_stage2;
    reg [CNT_WIDTH/2-1:0] cnt_lower_stage1, cnt_lower_stage2;
    
    // Terminal count segmentation for parallel comparison
    localparam [CNT_WIDTH/2-1:0] TERMINAL_UPPER = TERMINAL_CNT[CNT_WIDTH-1:CNT_WIDTH/2];
    localparam [CNT_WIDTH/2-1:0] TERMINAL_LOWER = TERMINAL_CNT[CNT_WIDTH/2-1:0];
    
    // Stage 1: Counter increment and segmentation
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage1 <= {CNT_WIDTH{1'b0}};
            cnt_upper_stage1 <= {(CNT_WIDTH/2){1'b0}};
            cnt_lower_stage1 <= {(CNT_WIDTH/2){1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            // Increment counter
            if (valid_stage4 && terminal_reached_stage3) begin
                cnt_stage1 <= {CNT_WIDTH{1'b0}};
            end else begin
                cnt_stage1 <= cnt_stage1 + 1'b1;
            end
            
            // Split counter into upper and lower segments for parallel comparison
            cnt_upper_stage1 <= cnt_stage1[CNT_WIDTH-1:CNT_WIDTH/2];
            cnt_lower_stage1 <= cnt_stage1[CNT_WIDTH/2-1:0];
        end
    end
    
    // Stage 2: Parallel comparison of upper and lower segments
    always @(posedge clk) begin
        if (rst) begin
            cnt_upper_stage2 <= {(CNT_WIDTH/2){1'b0}};
            cnt_lower_stage2 <= {(CNT_WIDTH/2){1'b0}};
            compare_result_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            cnt_upper_stage2 <= cnt_upper_stage1;
            cnt_lower_stage2 <= cnt_lower_stage1;
            valid_stage2 <= valid_stage1;
            
            // Parallel comparison with terminal segments
            compare_result_stage1 <= (cnt_upper_stage1 == TERMINAL_UPPER) && 
                                     (cnt_lower_stage1 == TERMINAL_LOWER);
        end
    end
    
    // Stage 3: Counter value forwarding and terminal detection
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage2 <= {CNT_WIDTH{1'b0}};
            terminal_reached_stage2 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            terminal_reached_stage2 <= compare_result_stage1;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Stage 4: Additional buffering for terminal signal
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage3 <= {CNT_WIDTH{1'b0}};
            terminal_reached_stage3 <= 1'b0;
            valid_stage4 <= 1'b0;
        end else begin
            cnt_stage3 <= cnt_stage2;
            terminal_reached_stage3 <= terminal_reached_stage2;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Stage 5: Clock output generation
    always @(posedge clk) begin
        if (rst) begin
            cnt_stage4 <= {CNT_WIDTH{1'b0}};
            clk_out <= 1'b0;
        end else begin
            cnt_stage4 <= cnt_stage3;
            
            if (valid_stage4 && terminal_reached_stage3) begin
                clk_out <= ~clk_out;
            end
        end
    end
endmodule