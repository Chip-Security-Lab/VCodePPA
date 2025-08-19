//SystemVerilog
module Demux_Pipelined #(
    parameter DW = 16,        // Data width
    parameter STAGES = 2      // Number of output stages
) (
    input wire clk,
    input wire rst_n,         // Added reset signal
    input wire valid_in,      // Added input valid signal
    input wire [DW-1:0] data_in,
    input wire [$clog2(STAGES)-1:0] stage_sel,
    output reg [STAGES-1:0][DW-1:0] pipe_out,
    output reg [STAGES-1:0] valid_out  // Added output valid signals
);

    // Pipeline stage 1 registers
    reg [DW-1:0] data_stage1;
    reg [$clog2(STAGES)-1:0] sel_stage1;
    reg valid_stage1;

    // Additional intermediate pipeline stage registers
    reg [DW-1:0] data_stage1_5;
    reg [$clog2(STAGES)-1:0] sel_stage1_5;
    reg valid_stage1_5;
    
    // Pipeline stage 2 registers
    reg [STAGES-1:0][DW-1:0] demux_stage2;
    reg [STAGES-1:0] valid_stage2;
    
    // One-hot encoded selection signal for early decoding
    reg [STAGES-1:0] sel_onehot_stage1_5;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DW{1'b0}};
            sel_stage1 <= {$clog2(STAGES){1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= data_in;
            sel_stage1 <= stage_sel;
            valid_stage1 <= valid_in;
        end
    end
    
    // Intermediate stage 1.5: Break critical path by pre-computing one-hot selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1_5 <= {DW{1'b0}};
            sel_stage1_5 <= {$clog2(STAGES){1'b0}};
            valid_stage1_5 <= 1'b0;
            sel_onehot_stage1_5 <= {STAGES{1'b0}};
        end else begin
            data_stage1_5 <= data_stage1;
            sel_stage1_5 <= sel_stage1;
            valid_stage1_5 <= valid_stage1;
            
            // Pre-compute one-hot encoded selection
            sel_onehot_stage1_5 <= {STAGES{1'b0}};
            if (valid_stage1) begin
                sel_onehot_stage1_5[sel_stage1] <= 1'b1;
            end
        end
    end
    
    // Stage 2: Perform demux operation using pre-computed one-hot selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            demux_stage2 <= {(STAGES*DW){1'b0}};
            valid_stage2 <= {STAGES{1'b0}};
        end else begin
            // Default all outputs to 0
            demux_stage2 <= {(STAGES*DW){1'b0}};
            valid_stage2 <= {STAGES{1'b0}};
            
            // Use pre-computed one-hot selection to directly assign data
            if (valid_stage1_5) begin
                valid_stage2 <= sel_onehot_stage1_5;
                
                // Simplified assignment using one-hot encoded selection
                for (int i = 0; i < STAGES; i++) begin
                    if (sel_onehot_stage1_5[i]) begin
                        demux_stage2[i] <= data_stage1_5;
                    end
                end
            end
        end
    end
    
    // Stage 3: Register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_out <= {(STAGES*DW){1'b0}};
            valid_out <= {STAGES{1'b0}};
        end else begin
            pipe_out <= demux_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule