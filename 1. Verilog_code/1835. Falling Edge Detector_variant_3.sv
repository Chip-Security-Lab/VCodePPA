//SystemVerilog
module falling_edge_detector (
    input  wire clock,
    input  wire async_reset,
    input  wire signal_input,
    output wire edge_out,
    output wire auto_reset_out
);
    // Stage 1 registers
    reg signal_delayed_stage1;
    reg signal_input_stage1;
    reg edge_detected_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg edge_detected_stage2;
    reg valid_stage2;
    reg [3:0] auto_reset_counter;
    reg auto_reset_out_reg;
    
    // Pipeline stage 1: Edge detection
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            signal_delayed_stage1 <= 1'b0;
            signal_input_stage1 <= 1'b0;
            edge_detected_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            signal_delayed_stage1 <= signal_input;
            signal_input_stage1 <= signal_input;
            edge_detected_stage1 <= ~signal_input & signal_delayed_stage1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2: Auto reset counter logic
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            edge_detected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            auto_reset_counter <= 4'b0;
            auto_reset_out_reg <= 1'b0;
        end else if (valid_stage1) begin
            edge_detected_stage2 <= edge_detected_stage1;
            valid_stage2 <= valid_stage1;
            
            if (edge_detected_stage1) begin
                auto_reset_counter <= 4'b1111;
                auto_reset_out_reg <= 1'b1;
            end else if (|auto_reset_counter) begin
                auto_reset_counter <= auto_reset_counter - 1'b1;
            end else begin
                auto_reset_out_reg <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign edge_out = edge_detected_stage2;
    assign auto_reset_out = auto_reset_out_reg;
    
endmodule