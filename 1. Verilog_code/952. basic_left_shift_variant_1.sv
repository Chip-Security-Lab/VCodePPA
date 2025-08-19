//SystemVerilog
module basic_left_shift #(parameter DATA_WIDTH = 8) (
    input  logic clk_i,
    input  logic rst_i,
    input  logic si,       // Serial input
    input  logic valid_i,   // Input valid signal
    output logic ready_o,   // Ready to accept new input
    output logic so,        // Serial output
    output logic valid_o    // Output valid signal
);
    // Split the shift register into multiple pipeline stages
    logic [DATA_WIDTH/4-1:0] sr_stage1;
    logic [DATA_WIDTH/4-1:0] sr_stage2;
    logic [DATA_WIDTH/4-1:0] sr_stage3;
    logic [DATA_WIDTH/4-1:0] sr_stage4;
    
    // Pipeline control signals
    logic valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    logic [3:0] pipeline_control;
    
    // Compute overall pipeline busy status
    assign ready_o = ~(|pipeline_control);
    
    // Pipeline stage 1
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sr_stage1 <= '0;
            valid_stage1 <= 1'b0;
            pipeline_control[0] <= 1'b0;
        end
        else if (valid_i && ready_o) begin
            sr_stage1 <= {sr_stage1[DATA_WIDTH/4-2:0], si};
            valid_stage1 <= 1'b1;
            pipeline_control[0] <= 1'b1;
        end
        else if (pipeline_control[0]) begin
            sr_stage1 <= {sr_stage1[DATA_WIDTH/4-2:0], si};
        end
    end
    
    // Pipeline stage 2
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sr_stage2 <= '0;
            valid_stage2 <= 1'b0;
            pipeline_control[1] <= 1'b0;
        end
        else if (valid_stage1) begin
            sr_stage2 <= {sr_stage2[DATA_WIDTH/4-2:0], sr_stage1[DATA_WIDTH/4-1]};
            valid_stage2 <= 1'b1;
            pipeline_control[1] <= 1'b1;
        end
        else if (pipeline_control[1]) begin
            sr_stage2 <= {sr_stage2[DATA_WIDTH/4-2:0], sr_stage1[DATA_WIDTH/4-1]};
        end
    end
    
    // Pipeline stage 3
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sr_stage3 <= '0;
            valid_stage3 <= 1'b0;
            pipeline_control[2] <= 1'b0;
        end
        else if (valid_stage2) begin
            sr_stage3 <= {sr_stage3[DATA_WIDTH/4-2:0], sr_stage2[DATA_WIDTH/4-1]};
            valid_stage3 <= 1'b1;
            pipeline_control[2] <= 1'b1;
        end
        else if (pipeline_control[2]) begin
            sr_stage3 <= {sr_stage3[DATA_WIDTH/4-2:0], sr_stage2[DATA_WIDTH/4-1]};
        end
    end
    
    // Pipeline stage 4
    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            sr_stage4 <= '0;
            valid_stage4 <= 1'b0;
            pipeline_control[3] <= 1'b0;
        end
        else if (valid_stage3) begin
            sr_stage4 <= {sr_stage4[DATA_WIDTH/4-2:0], sr_stage3[DATA_WIDTH/4-1]};
            valid_stage4 <= 1'b1;
            pipeline_control[3] <= 1'b1;
        end
        else if (pipeline_control[3]) begin
            sr_stage4 <= {sr_stage4[DATA_WIDTH/4-2:0], sr_stage3[DATA_WIDTH/4-1]};
        end
    end
    
    // Connect the output to the MSB of the last stage
    assign so = sr_stage4[DATA_WIDTH/4-1];
    assign valid_o = valid_stage4;
    
    // Pipeline status monitoring (optional for debugging)
    /* verilator lint_off UNUSED */
    logic [3:0] pipeline_status;
    assign pipeline_status = {valid_stage4, valid_stage3, valid_stage2, valid_stage1};
    /* verilator lint_on UNUSED */
    
endmodule