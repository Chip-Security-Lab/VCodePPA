//SystemVerilog
module async_reset_shifter #(parameter WIDTH = 10) (
    input wire i_clk, i_arst_n, i_en,
    input wire i_data,
    output wire o_data
);
    // Split the shifter into multiple pipeline stages with improved timing
    // Reduced stage width for shorter combinational paths
    localparam STAGE_WIDTH = 2;  // Each stage handles 2 bits
    localparam NUM_STAGES = (WIDTH + STAGE_WIDTH - 1) / STAGE_WIDTH;
    
    // Pipeline registers for data path
    reg [STAGE_WIDTH-1:0] r_stage [0:NUM_STAGES-1];
    // Pipeline registers for control path
    reg [NUM_STAGES-1:0] r_valid;
    // Additional pipeline registers for critical path cutting
    reg [NUM_STAGES-2:0] r_stage_buffer;
    
    // First stage receives the input data
    always @(posedge i_clk or negedge i_arst_n) begin
        if (!i_arst_n) begin
            r_stage[0] <= {STAGE_WIDTH{1'b0}};
            r_valid[0] <= 1'b0;
        end
        else if (i_en) begin
            r_stage[0] <= {i_data, (STAGE_WIDTH > 1) ? r_stage[0][STAGE_WIDTH-1:1] : 1'b0};
            r_valid[0] <= 1'b1;
        end
    end
    
    // Critical path buffers to cut long paths between stages
    genvar j;
    generate
        for (j = 0; j < NUM_STAGES-1; j = j + 1) begin : buffer_gen
            always @(posedge i_clk or negedge i_arst_n) begin
                if (!i_arst_n) begin
                    r_stage_buffer[j] <= 1'b0;
                end
                else if (i_en) begin
                    // Pipeline register to cut critical path
                    r_stage_buffer[j] <= r_stage[j][0];
                end
            end
        end
    endgenerate
    
    // Generate intermediate pipeline stages with critical path cutting
    genvar i;
    generate
        for (i = 1; i < NUM_STAGES; i = i + 1) begin : stage_gen
            always @(posedge i_clk or negedge i_arst_n) begin
                if (!i_arst_n) begin
                    r_stage[i] <= {STAGE_WIDTH{1'b0}};
                    r_valid[i] <= 1'b0;
                end
                else if (i_en) begin
                    // Connect stages using buffered data to reduce critical path
                    r_stage[i] <= {r_stage_buffer[i-1], (STAGE_WIDTH > 1) ? r_stage[i][STAGE_WIDTH-1:1] : 1'b0};
                    r_valid[i] <= r_valid[i-1];
                end
            end
        end
    endgenerate
    
    // Output is the LSB of the last stage
    assign o_data = r_stage[NUM_STAGES-1][0];
    
endmodule