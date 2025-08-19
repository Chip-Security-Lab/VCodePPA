//SystemVerilog
module int_ctrl_threshold #(
    parameter WIDTH = 6,
    parameter THRESHOLD = 3
)(
    input clk, rst,
    input [WIDTH-1:0] req,
    output reg valid,
    output reg [2:0] code
);
    // Create a mask for values >= THRESHOLD
    wire [WIDTH-1:0] masked_req = req & ~((1 << THRESHOLD) - 1);
    
    // Registered input and intermediate signals
    reg [WIDTH-1:0] masked_req_buf;
    reg valid_pre;
    
    // Priority encoder signals - moved before logic
    reg [2:0] priority_code_stage1, priority_code_stage2;
    reg found_priority_stage1, found_priority_stage2;
    reg [2:0] i_buf1, i_buf2;
    
    always @(posedge clk) begin
        if(rst) begin
            masked_req_buf <= {WIDTH{1'b0}};
        end else begin
            // Register input early 
            masked_req_buf <= masked_req;
        end
    end
    
    // First retiming stage - priority encoder first half
    always @(posedge clk) begin
        if(rst) begin
            priority_code_stage1 <= 3'b0;
            found_priority_stage1 <= 1'b0;
        end else begin
            priority_code_stage1 <= 3'b0;
            found_priority_stage1 <= 1'b0;
            
            for(i_buf1 = 0; i_buf1 < WIDTH/2; i_buf1 = i_buf1 + 1) begin
                if(masked_req_buf[i_buf1] && !found_priority_stage1) begin
                    priority_code_stage1 <= i_buf1[2:0];
                    found_priority_stage1 <= 1'b1;
                end
            end
        end
    end
    
    // Second retiming stage - priority encoder second half
    always @(posedge clk) begin
        if(rst) begin
            priority_code_stage2 <= 3'b0;
            found_priority_stage2 <= 1'b0;
            valid_pre <= 1'b0;
        end else begin
            priority_code_stage2 <= priority_code_stage1;
            found_priority_stage2 <= found_priority_stage1;
            valid_pre <= |masked_req_buf;
            
            for(i_buf2 = WIDTH/2; i_buf2 < WIDTH; i_buf2 = i_buf2 + 1) begin
                if(masked_req_buf[i_buf2] && !found_priority_stage1) begin
                    priority_code_stage2 <= i_buf2[2:0];
                    found_priority_stage2 <= 1'b1;
                end
            end
        end
    end
    
    // Final output stage 
    always @(posedge clk) begin
        if(rst) begin
            valid <= 1'b0;
            code <= 3'b0;
        end else begin
            valid <= valid_pre;
            code <= priority_code_stage2;
        end
    end
endmodule