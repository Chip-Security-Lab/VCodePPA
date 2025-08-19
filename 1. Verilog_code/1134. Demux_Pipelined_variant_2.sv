//SystemVerilog
//IEEE 1364-2005
module Demux_Pipelined #(parameter DW=16, STAGES=2) (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire [DW-1:0] data_in,
    input wire [$clog2(STAGES)-1:0] stage_sel,
    output reg [STAGES-1:0][DW-1:0] pipe_out,
    output reg valid_out
);

    // Stage 1 registers
    reg [DW-1:0] data_stage1;
    reg [$clog2(STAGES)-1:0] sel_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [DW-1:0] data_stage2;
    reg [$clog2(STAGES)-1:0] sel_stage2;
    reg valid_stage2;
    
    // Stage 3 registers - Added new stage
    reg [STAGES-1:0] decoded_sel_stage3;
    reg [DW-1:0] data_stage3;
    reg valid_stage3;
    
    // Stage 4 registers - Added new stage
    reg [STAGES-1:0] decoded_sel_stage4;
    reg [DW-1:0] data_stage4;
    reg valid_stage4;
    
    // Pre-decode selection at the input stage to reduce critical path
    reg [STAGES-1:0] pre_decoded_sel;
    
    // Generate pre-decoded selection based on input selection
    always_comb begin
        pre_decoded_sel = {STAGES{1'b0}};
        if (valid_in)
            pre_decoded_sel[stage_sel] = 1'b1;
    end
    
    // Pipeline Stage 1: Register inputs
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
    
    // Pipeline Stage 2: Register pre-decoded selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DW{1'b0}};
            sel_stage2 <= {$clog2(STAGES){1'b0}};
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            sel_stage2 <= sel_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Decode selection and prepare
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_sel_stage3 <= {STAGES{1'b0}};
            data_stage3 <= {DW{1'b0}};
            valid_stage3 <= 1'b0;
        end else begin
            decoded_sel_stage3 <= {STAGES{1'b0}};
            if (valid_stage2)
                decoded_sel_stage3[sel_stage2] <= 1'b1;
            
            data_stage3 <= data_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Pipeline Stage 4: Prepare final data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_sel_stage4 <= {STAGES{1'b0}};
            data_stage4 <= {DW{1'b0}};
            valid_stage4 <= 1'b0;
        end else begin
            decoded_sel_stage4 <= decoded_sel_stage3;
            data_stage4 <= data_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // Registered enable signals for each output path
    reg [STAGES-1:0] output_enables_stage5;
    reg [DW-1:0] data_stage5;
    reg valid_stage5;
    
    // Pipeline Stage 5: Compute output enables
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_enables_stage5 <= {STAGES{1'b0}};
            data_stage5 <= {DW{1'b0}};
            valid_stage5 <= 1'b0;
        end else begin
            for (int i = 0; i < STAGES; i = i + 1) begin
                output_enables_stage5[i] <= decoded_sel_stage4[i] && valid_stage4;
            end
            data_stage5 <= data_stage4;
            valid_stage5 <= valid_stage4;
        end
    end
    
    // Pipeline Stage 6: Final output generation with balanced paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_out <= {STAGES{{{DW{1'b0}}}}};
            valid_out <= 1'b0;
        end else begin
            // Parallel update of all outputs using pre-computed enables
            for (int i = 0; i < STAGES; i = i + 1) begin
                if (output_enables_stage5[i])
                    pipe_out[i] <= data_stage5;
            end
            valid_out <= valid_stage5;
        end
    end

endmodule