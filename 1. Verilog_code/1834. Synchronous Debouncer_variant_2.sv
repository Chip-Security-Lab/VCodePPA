//SystemVerilog
module rising_edge_detector #(parameter COUNT_LIMIT = 4) (
    input  wire clk_in,
    input  wire rst_n,
    input  wire signal_in,
    output reg  edge_detected,
    output reg [$clog2(COUNT_LIMIT):0] edge_count
);
    // Pipeline stage 1: Input capture
    reg signal_stage1;
    
    // Pipeline stage 2: Edge detection preparation
    reg signal_stage2;
    reg signal_stage2_delayed;
    
    // Pipeline stage 3: Edge detection
    reg edge_found_stage3;
    
    // Pipeline stage 4: Counter logic preparation
    reg edge_found_stage4;
    reg [$clog2(COUNT_LIMIT):0] edge_count_stage4;
    reg [$clog2(COUNT_LIMIT):0] next_count_stage4;
    reg count_reset_stage4;
    
    // Pipeline stage 5: Final output generation
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            signal_stage1 <= 1'b0;
            signal_stage2 <= 1'b0;
            signal_stage2_delayed <= 1'b0;
            edge_found_stage3 <= 1'b0;
            edge_found_stage4 <= 1'b0;
            edge_count_stage4 <= {$clog2(COUNT_LIMIT)+1{1'b0}};
            next_count_stage4 <= {$clog2(COUNT_LIMIT)+1{1'b0}};
            count_reset_stage4 <= 1'b0;
            edge_detected <= 1'b0;
            edge_count <= {$clog2(COUNT_LIMIT)+1{1'b0}};
        end else begin
            // Stage 1: Capture input signal
            signal_stage1 <= signal_in;
            
            // Stage 2: Prepare for edge detection
            signal_stage2 <= signal_stage1;
            signal_stage2_delayed <= signal_stage2;
            
            // Stage 3: Detect edge
            edge_found_stage3 <= signal_stage2 & ~signal_stage2_delayed;
            
            // Stage 4: Prepare counter logic
            edge_found_stage4 <= edge_found_stage3;
            
            if (edge_found_stage3) begin
                count_reset_stage4 <= (edge_count_stage4 == COUNT_LIMIT - 1'b1);
                next_count_stage4 <= count_reset_stage4 ? {$clog2(COUNT_LIMIT)+1{1'b0}} : edge_count_stage4 + 1'b1;
                edge_count_stage4 <= next_count_stage4;
            end
            
            // Stage 5: Generate final outputs
            edge_detected <= edge_found_stage4;
            edge_count <= edge_count_stage4;
        end
    end
endmodule