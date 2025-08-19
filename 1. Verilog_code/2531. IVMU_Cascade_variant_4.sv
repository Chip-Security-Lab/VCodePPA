//SystemVerilog
module IVMU_Cascade_Pipelined #(parameter N=2) (
    input clk,
    input rst_n,
    input [N*4-1:0] casc_irq,
    output wire [3:0] highest_irq_o, // Registered output data
    output wire valid_o // Registered output flag indicating if any group was high
);

    // Registered signals for each pipeline stage
    // stage_data_reg[k] holds the selected 4-bit data after considering groups 0 to k
    // stage_found_reg[k] is true if an active group was found among groups 0 to k
    reg [3:0] stage_data_reg [0:N-1];
    reg stage_found_reg [0:N-1];

    // Combinational signals within each stage
    // group_any_high[i] indicates if any bit is high in the i-th 4-bit group of casc_irq
    wire [N-1:0] group_any_high;

    // Calculate group_any_high combinatorially for all groups
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_group_any_high_comb
            assign group_any_high[i] = |casc_irq[i*4 +: 4];
        end
    endgenerate

    // Pipeline stages to implement priority encoding
    // Each stage 'i' processes group 'i', considering results from stage 'i-1'
    generate
        for (i = 0; i < N; i = i + 1) begin : gen_pipeline_stage

            // Inputs to the current stage 'i' come from the registered outputs of stage 'i-1'
            // For stage 0, initial values are used (data=0, found=false)
            wire [3:0] data_in_stage = (i == 0) ? 4'b0 : stage_data_reg[i-1];
            wire found_in_stage = (i == 0) ? 1'b0 : stage_found_reg[i-1];

            // Combinational logic for the current stage 'i'
            // If a higher priority group (0 to i-1) was already found, pass its result
            // Otherwise, check group 'i'. If active, select its data. If not, pass default (0).
            wire [3:0] data_next_stage;
            wire found_next_stage;

            assign data_next_stage = found_in_stage ? data_in_stage :
                                     (group_any_high[i] ? casc_irq[i*4 +: 4] : data_in_stage);

            // The 'found' flag is true if a higher priority group was found OR group 'i' is active
            assign found_next_stage = found_in_stage | group_any_high[i];

            // Registers for the current stage 'i'
            // These registers store the result after considering groups 0 through 'i'
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_data_reg[i] <= 4'b0;
                    stage_found_reg[i] <= 1'b0;
                end else begin
                    stage_data_reg[i] <= data_next_stage;
                    stage_found_reg[i] <= found_next_stage;
                end
            end
        end
    endgenerate

    // The final output comes from the last pipeline stage (N-1)
    // This output is registered and represents the highest priority active group found
    assign highest_irq_o = stage_data_reg[N-1];
    assign valid_o = stage_found_reg[N-1];

endmodule