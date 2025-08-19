//SystemVerilog
module MultiPhaseShiftReg #(
    parameter PHASES = 4, 
    parameter WIDTH = 8
)(
    input wire [PHASES-1:0] phase_clk,
    input wire serial_in,
    input wire rst_n,                     // Reset signal (active low)
    input wire enable,                    // Pipeline enable signal
    output wire [PHASES-1:0] phase_out,
    output wire pipeline_valid            // Indicates valid data in pipeline
);
    // Pipelined shift registers (3 pipeline stages)
    reg [WIDTH-1:0] shift_reg_stage1 [0:PHASES-1];
    reg [WIDTH-1:0] shift_reg_stage2 [0:PHASES-1];
    reg [WIDTH-1:0] shift_reg_stage3 [0:PHASES-1];
    
    // Pipeline control signals
    reg [2:0] valid_pipeline;  // Valid flags for each stage
    
    // Intermediate connection signals between stages
    wire [PHASES-1:0] inter_data_stage1;
    wire [PHASES-1:0] inter_data_stage2;
    
    // Generate pipeline valid output
    assign pipeline_valid = valid_pipeline[2];
    
    // Pipeline control logic
    always @(posedge phase_clk[0] or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipeline <= 3'b000;
        end else if (enable) begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b1};
        end
    end
    
    genvar i;
    generate
        for(i=0; i<PHASES; i=i+1) begin : phase_pipeline_gen
            // Stage 1: Input processing
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    shift_reg_stage1[i] <= {WIDTH{1'b0}};
                end else if (enable) begin
                    shift_reg_stage1[i] <= {shift_reg_stage1[i][WIDTH-2:0], serial_in};
                end
            end
            assign inter_data_stage1[i] = shift_reg_stage1[i][WIDTH-1];
            
            // Stage 2: Middle processing
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    shift_reg_stage2[i] <= {WIDTH{1'b0}};
                end else if (enable) begin
                    shift_reg_stage2[i] <= {shift_reg_stage2[i][WIDTH-2:0], inter_data_stage1[i]};
                end
            end
            assign inter_data_stage2[i] = shift_reg_stage2[i][WIDTH-1];
            
            // Stage 3: Output processing
            always @(posedge phase_clk[i] or negedge rst_n) begin
                if (!rst_n) begin
                    shift_reg_stage3[i] <= {WIDTH{1'b0}};
                end else if (enable) begin
                    shift_reg_stage3[i] <= {shift_reg_stage3[i][WIDTH-2:0], inter_data_stage2[i]};
                end
            end
            
            // Connect final output
            assign phase_out[i] = shift_reg_stage3[i][WIDTH-1];
        end
    endgenerate
endmodule