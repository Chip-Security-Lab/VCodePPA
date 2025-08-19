//SystemVerilog
module wave7_ramp_up #(
    parameter WIDTH = 8,
    parameter STEP  = 2,
    parameter PIPELINE_STAGES = 3  // Number of pipeline stages
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             data_valid_in,  // Input valid signal
    output wire             data_ready_in,  // Ready to accept input
    output reg              data_valid_out, // Output valid signal
    input  wire             data_ready_out, // Downstream ready
    output reg [WIDTH-1:0]  wave_out
);
    // Pipeline stage registers for value
    reg [WIDTH-1:0] value_stage1, value_stage2;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2;
    
    // Pipeline ready signals (propagated backward)
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // Assign ready signals for each stage
    assign ready_stage3 = data_ready_out;
    assign ready_stage2 = !valid_stage2 || ready_stage3;
    assign ready_stage1 = !valid_stage1 || ready_stage2;
    assign data_ready_in = !data_valid_in || ready_stage1;
    
    // Stage 1: Initialize or increment the value
    always @(posedge clk) begin
        if (rst) begin
            value_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (ready_stage1) begin
            if (data_valid_in) begin
                value_stage1 <= (value_stage2 + STEP);
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Pass to next stage
    always @(posedge clk) begin
        if (rst) begin
            value_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (ready_stage2) begin
            value_stage2 <= value_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Final stage: Output the result
    always @(posedge clk) begin
        if (rst) begin
            wave_out <= {WIDTH{1'b0}};
            data_valid_out <= 1'b0;
        end else if (ready_stage3) begin
            wave_out <= value_stage2;
            data_valid_out <= valid_stage2;
        end
    end
endmodule