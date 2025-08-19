//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_monitor(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] reset_inputs,
    input  wire       input_valid,
    output reg  [3:0] reset_outputs,
    output reg  [3:0] reset_status,
    output reg        output_valid
);
    // Pipeline stage registers
    // Stage 1: Input capture
    reg [3:0] reset_inputs_reg;
    reg       valid_reg;
    
    // Stage 2: Processing stage
    reg [3:0] reset_data_stage2;
    reg       valid_stage2;
    
    // Stage 3: Pre-output stage
    reg [3:0] reset_data_stage3;
    reg       valid_stage3;
    
    //---------------------------------
    // Stage 1: Input Capture Pipeline
    //---------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_inputs_reg <= 4'b0000;
            valid_reg <= 1'b0;
        end else begin
            reset_inputs_reg <= reset_inputs;
            valid_reg <= input_valid;
        end
    end
    
    //---------------------------------
    // Stage 2: Processing Pipeline
    //---------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_data_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            reset_data_stage2 <= reset_inputs_reg;
            valid_stage2 <= valid_reg;
        end
    end
    
    //---------------------------------
    // Stage 3: Pre-output Pipeline
    //---------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_data_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end else begin
            reset_data_stage3 <= reset_data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    //---------------------------------
    // Output Stage: Final Formatting
    //---------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_outputs <= 4'b0000;
            reset_status <= 4'b0000;
            output_valid <= 1'b0;
        end else begin
            reset_outputs <= reset_data_stage3;
            reset_status <= reset_data_stage3;
            output_valid <= valid_stage3;
        end
    end
    
endmodule