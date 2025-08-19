//SystemVerilog
// Top-level module - Pipelined implementation
module RD1 #(
    parameter DW = 8,
    parameter PIPELINE_STAGES = 3  // Configurable pipeline depth
)(
    input clk,
    input rst,
    input valid_in,              // Input data valid signal
    output ready_in,             // Ready to accept new input
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid_out             // Output data valid signal
);
    // Pipeline stage signals
    wire [DW-1:0] stage1_data, stage2_data, stage3_data;
    wire valid_stage1, valid_stage2, valid_stage3;
    wire ready_stage1, ready_stage2, ready_stage3;
    
    // First pipeline stage - Reset logic
    Reset_Controller_Pipelined #(
        .DW(DW)
    ) reset_ctrl_stage1 (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .ready_out(ready_in),
        .ready_in(ready_stage2),
        .valid_out(valid_stage1),
        .din(din),
        .stage_data(stage1_data)
    );
    
    // Second pipeline stage - Intermediate processing
    Pipeline_Stage #(
        .DW(DW)
    ) middle_stage (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_stage1),
        .ready_out(ready_stage2),
        .ready_in(ready_stage3),
        .valid_out(valid_stage2),
        .data_in(stage1_data),
        .data_out(stage2_data)
    );
    
    // Third pipeline stage - Data Register
    Data_Register_Pipelined #(
        .DW(DW)
    ) data_reg_stage3 (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_stage2),
        .ready_out(ready_stage3),
        .valid_out(valid_out),
        .next_data(stage2_data),
        .dout(dout)
    );
    
endmodule

// Reset Controller with pipeline registers
module Reset_Controller_Pipelined #(
    parameter DW = 8
)(
    input clk,
    input rst,
    input valid_in,
    input ready_in,
    output ready_out,
    output reg valid_out,
    input [DW-1:0] din,
    output reg [DW-1:0] stage_data
);
    wire [DW-1:0] reset_data;
    
    // Reset logic
    assign reset_data = rst ? {DW{1'b0}} : din;
    
    // Flow control
    assign ready_out = ready_in || !valid_out;
    
    // Register stage
    always @(posedge clk) begin
        if (rst) begin
            stage_data <= {DW{1'b0}};
            valid_out <= 1'b0;
        end
        else if (ready_out) begin
            stage_data <= reset_data;
            valid_out <= valid_in;
        end
    end
    
endmodule

// Pipeline intermediate stage
module Pipeline_Stage #(
    parameter DW = 8
)(
    input clk,
    input rst,
    input valid_in,
    input ready_in,
    output ready_out,
    output reg valid_out,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // Additional processing could be added here
    wire [DW-1:0] processed_data;
    
    // Simple processing (could be more complex in real designs)
    assign processed_data = data_in;
    
    // Flow control
    assign ready_out = ready_in || !valid_out;
    
    // Register stage
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DW{1'b0}};
            valid_out <= 1'b0;
        end
        else if (ready_out) begin
            data_out <= processed_data;
            valid_out <= valid_in;
        end
    end
    
endmodule

// Data Register with pipeline control
module Data_Register_Pipelined #(
    parameter DW = 8
)(
    input clk,
    input rst,
    input valid_in,
    output ready_out,
    output reg valid_out,
    input [DW-1:0] next_data,
    output reg [DW-1:0] dout
);
    // This is the final stage, always ready to accept data
    assign ready_out = 1'b1;
    
    // Register update on clock edge with valid control
    always @(posedge clk) begin
        if (rst) begin
            dout <= {DW{1'b0}};
            valid_out <= 1'b0;
        end
        else if (valid_in) begin
            dout <= next_data;
            valid_out <= valid_in;
        end
    end
    
endmodule