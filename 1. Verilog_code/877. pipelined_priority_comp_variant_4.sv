//SystemVerilog
// SystemVerilog

// Module: priority_encoder
// Description: Finds the index of the most significant bit set in the input data.
module priority_encoder #(parameter WIDTH = 16)(
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] priority_out
);

    reg [$clog2(WIDTH)-1:0] priority_reg;
    integer i;

    always @(*) begin
        priority_reg = 0; // Default to 0 if no bit is set
        for (i = WIDTH - 1; i >= 0; i = i - 1) begin
            if (data_in[i]) begin
                priority_reg = i[$clog2(WIDTH)-1:0];
            end
        end
    end

    assign priority_out = priority_reg;

endmodule

// Module: pipeline_stage
// Description: A single stage of a pipeline register.
module pipeline_stage #(parameter DATA_WIDTH = 16)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            valid_out <= 0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end

endmodule

// Module: pipelined_priority_comp
// Description: Pipelined priority computation module.
// Breaks down the original flat module into pipeline stages and a priority encoder.
module pipelined_priority_comp #(parameter WIDTH = 16, STAGES = 2)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output [$clog2(WIDTH)-1:0] priority_out,
    output valid_out
);

    // Internal signals for pipeline stages
    wire [WIDTH-1:0] stage_data_in [0:STAGES];
    wire stage_valid_in [0:STAGES];

    // Connect input to the first stage
    assign stage_data_in[0] = data_in;
    assign stage_valid_in[0] = |data_in; // Valid if any bit is set


    // Instantiate pipeline stages
    generate
        for (genvar s = 0; s < STAGES; s = s + 1) begin : pipeline_stages_gen
            pipeline_stage #(
                .DATA_WIDTH(WIDTH)
            ) stage (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(stage_data_in[s]),
                .valid_in(stage_valid_in[s]),
                .data_out(stage_data_in[s+1]), // Output of stage s is input to stage s+1
                .valid_out(stage_valid_in[s+1])
            );
        end
    endgenerate

    // Instantiate priority encoder for the last stage output
    priority_encoder #(
        .WIDTH(WIDTH)
    ) encoder (
        .data_in(stage_data_in[STAGES]),
        .priority_out(priority_out)
    );

    // Output valid signal from the last stage
    assign valid_out = stage_valid_in[STAGES];

endmodule