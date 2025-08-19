//SystemVerilog
module basic_right_shift #(parameter WIDTH = 8) (
    input wire clk,
    input wire reset_n,
    input wire serial_in,
    input wire valid_in,
    output wire serial_out,
    output wire valid_out
);
    // Define pipeline stages
    localparam STAGES = 2;
    localparam STAGE_WIDTH = (WIDTH + STAGES - 1) / STAGES;
    
    // Pipeline registers for shift data
    reg [STAGE_WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-STAGE_WIDTH-1:0] shift_reg_stage2;
    
    // Pipeline valid signals
    reg valid_stage1, valid_stage2;
    
    // Stage 1 processing
    always @(posedge clk) begin
        if (!reset_n) begin
            shift_reg_stage1 <= {STAGE_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            if (valid_in) begin
                shift_reg_stage1 <= {serial_in, shift_reg_stage1[STAGE_WIDTH-1:1]};
                valid_stage1 <= 1'b1;
            end
            else if (valid_stage1 && valid_stage2) begin
                // Continue shifting when pipeline is flowing
                shift_reg_stage1 <= {serial_in, shift_reg_stage1[STAGE_WIDTH-1:1]};
            end
            else begin
                valid_stage1 <= valid_in;
            end
        end
    end
    
    // Stage 2 processing
    always @(posedge clk) begin
        if (!reset_n) begin
            shift_reg_stage2 <= {(WIDTH-STAGE_WIDTH){1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            if (valid_stage1) begin
                shift_reg_stage2 <= {shift_reg_stage1[0], shift_reg_stage2[WIDTH-STAGE_WIDTH-1:1]};
                valid_stage2 <= 1'b1;
            end
            else if (valid_stage2) begin
                // Continue shifting when data is still in pipeline
                shift_reg_stage2 <= {1'b0, shift_reg_stage2[WIDTH-STAGE_WIDTH-1:1]};
            end
            else begin
                valid_stage2 <= valid_stage1;
            end
        end
    end
    
    // Output assignments
    assign serial_out = shift_reg_stage2[0];
    assign valid_out = valid_stage2;
endmodule