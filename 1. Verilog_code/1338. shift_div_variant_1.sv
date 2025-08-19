//SystemVerilog
// Top-level module
module shift_div #(parameter PATTERN=8'b1010_1100) (
    input  wire clk,
    input  wire rst,
    output wire clk_out
);
    // Internal connections between stages
    wire stage1_valid, stage2_valid;
    wire stage1_ready, stage2_ready;
    wire [3:0] stage1_data;
    wire [3:0] stage2_data;
    wire feedback_bit;
    
    // Control signals
    assign stage1_ready = 1'b1; // Always ready to accept new data
    assign stage2_ready = 1'b1; // Always ready to accept data from stage 1
    
    // Assign output from the second stage's MSB
    assign clk_out = stage2_data[3];
    
    // Feedback connection
    assign feedback_bit = stage2_data[3];
    
    // Instantiate first pipeline stage
    shift_stage #(
        .INIT_VALUE(PATTERN[3:0]),
        .STAGE_ID(1)
    ) stage1_inst (
        .clk(clk),
        .rst(rst),
        .ready_in(stage1_ready),
        .valid_out(stage1_valid),
        .feedback_bit(feedback_bit),
        .data_out(stage1_data)
    );
    
    // Instantiate second pipeline stage
    shift_stage #(
        .INIT_VALUE(PATTERN[7:4]),
        .STAGE_ID(2)
    ) stage2_inst (
        .clk(clk),
        .rst(rst),
        .ready_in(stage2_ready),
        .valid_out(stage2_valid),
        .feedback_bit(stage1_data[3]),
        .data_out(stage2_data)
    );
endmodule

// Pipeline stage submodule
module shift_stage #(
    parameter [3:0] INIT_VALUE = 4'b0000,
    parameter STAGE_ID = 0
)(
    input  wire clk,
    input  wire rst,
    input  wire ready_in,
    input  wire feedback_bit,
    output reg  valid_out,
    output reg  [3:0] data_out
);
    // Shift register operation
    always @(posedge clk) begin
        if (rst) begin
            data_out <= INIT_VALUE;
            valid_out <= 1'b1;
        end
        else if (ready_in) begin
            // Shift and insert feedback bit
            data_out <= {data_out[2:0], feedback_bit};
            valid_out <= 1'b1;
        end
    end
endmodule