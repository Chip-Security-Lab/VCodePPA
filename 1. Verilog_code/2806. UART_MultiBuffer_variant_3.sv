//SystemVerilog
module UART_MultiBuffer_Pipelined #(
    parameter BUFFER_LEVEL = 4
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [7:0]        rx_data,
    input  wire              rx_valid,
    output wire [7:0]        buffer_occupancy,
    input  wire              buffer_flush
);

    // Pipeline registers for data and valid signals after first combinational stage
    reg [7:0] data_stage [0:BUFFER_LEVEL-1];
    reg       valid_stage [0:BUFFER_LEVEL-1];

    // Intermediate combinational wires for pipeline progression
    wire [7:0] data_comb [0:BUFFER_LEVEL-1];
    wire       valid_comb [0:BUFFER_LEVEL-1];

    integer i;

    // Pipeline combinational logic before registers
    // Stage 0: combinational logic only, no register at input
    assign data_comb[0]  = rx_data;
    assign valid_comb[0] = rx_valid;

    // Pipeline progression logic: combinationally propagating previous register output
    generate
        genvar stage_idx;
        for (stage_idx = 1; stage_idx < BUFFER_LEVEL; stage_idx = stage_idx + 1) begin : PIPELINE_STAGE
            assign data_comb[stage_idx]  = data_stage[stage_idx-1];
            assign valid_comb[stage_idx] = valid_stage[stage_idx-1];
        end
    endgenerate

    // Valid pipeline flush logic
    wire flush_all = buffer_flush | ~rst_n;

    // Pipeline registers update: registers moved after combinational stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
                data_stage[i]  <= 8'b0;
                valid_stage[i] <= 1'b0;
            end
        end else if (flush_all) begin
            for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
                data_stage[i]  <= 8'b0;
                valid_stage[i] <= 1'b0;
            end
        end else begin
            for (i = 0; i < BUFFER_LEVEL; i = i + 1) begin
                data_stage[i]  <= data_comb[i];
                valid_stage[i] <= valid_comb[i];
            end
        end
    end

    // Buffer occupancy calculation
    reg [3:0] occupancy_count;
    integer j;
    always @(*) begin
        occupancy_count = 4'b0;
        for (j = 0; j < BUFFER_LEVEL; j = j + 1) begin
            occupancy_count = occupancy_count + valid_stage[j];
        end
    end

    assign buffer_occupancy = {4'b0, occupancy_count};

endmodule