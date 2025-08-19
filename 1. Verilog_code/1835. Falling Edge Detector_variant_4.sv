//SystemVerilog
module falling_edge_detector (
    input  wire       clock,
    input  wire       async_reset,
    input  wire       signal_input,
    output reg        edge_out,
    output reg        auto_reset_out
);
    // Stage 1 registers - Edge detection
    reg signal_delayed_stage1;
    reg signal_input_stage1;
    reg edge_detected_stage1;
    
    // Stage 2 registers - Counter logic
    reg edge_detected_stage2;
    reg [3:0] auto_reset_counter_stage2;
    reg auto_reset_out_stage2;
    
    // Stage 1: Edge detection
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            signal_delayed_stage1 <= 1'b0;
            signal_input_stage1 <= 1'b0;
            edge_detected_stage1 <= 1'b0;
        end else begin
            signal_delayed_stage1 <= signal_input;
            signal_input_stage1 <= signal_input;
            edge_detected_stage1 <= ~signal_input & signal_delayed_stage1;
        end
    end
    
    // Stage 2: Counter and auto-reset logic
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            edge_detected_stage2 <= 1'b0;
            auto_reset_counter_stage2 <= 4'b0;
            auto_reset_out_stage2 <= 1'b0;
        end else begin
            edge_detected_stage2 <= edge_detected_stage1;
            
            if (edge_detected_stage2) begin
                auto_reset_counter_stage2 <= 4'b1111;
                auto_reset_out_stage2 <= 1'b1;
            end else if (|auto_reset_counter_stage2) begin
                auto_reset_counter_stage2 <= auto_reset_counter_stage2 - 1'b1;
            end else begin
                auto_reset_out_stage2 <= 1'b0;
            end
        end
    end
    
    // Output assignment
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            edge_out <= 1'b0;
            auto_reset_out <= 1'b0;
        end else begin
            edge_out <= edge_detected_stage2;
            auto_reset_out <= auto_reset_out_stage2;
        end
    end
endmodule