//SystemVerilog
module pipelined_priority_comp #(parameter WIDTH = 16, STAGES = 2)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input valid_in,
    output [$clog2(WIDTH)-1:0] priority_out,
    output valid_out
);

    // Internal pipeline registers
    reg [WIDTH-1:0] stage_data [0:STAGES-1];
    reg [STAGES-1:0] stage_valid;
    reg [$clog2(WIDTH)-1:0] stage_priority [0:STAGES-1];

    // Pipeline stages processing
    generate
        genvar s;
        for (s = 0; s < STAGES; s = s + 1) begin : pipeline_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_data[s] <= 0;
                    stage_valid[s] <= 0;
                    stage_priority[s] <= 0;
                end else if (s == 0) begin
                    // Input stage
                    stage_data[s] <= data_in;
                    stage_valid[s] <= valid_in;
                    // Initial priority calculation for the first stage
                    stage_priority[s] <= 0;
                    for (int i = WIDTH - 1; i >= 0; i = i - 1) begin
                        if (data_in[i]) begin
                            stage_priority[s] <= i[$clog2(WIDTH)-1:0];
                        end
                    end
                end else begin // s > 0
                    // Intermediate stages propagate data and valid
                    stage_data[s] <= stage_data[s-1];
                    stage_valid[s] <= stage_valid[s-1];
                    // Propagate priority from previous stage
                    stage_priority[s] <= stage_priority[s-1];
                end
            end
        end
    endgenerate

    // Output stage
    assign valid_out = stage_valid[STAGES-1];
    assign priority_out = stage_priority[STAGES-1];

endmodule