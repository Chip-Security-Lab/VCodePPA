//SystemVerilog
// Top-level module: Pipelined Asynchronous Logical Right Shifter
module pipelined_async_logical_right_shifter #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_WIDTH = 4
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire [DATA_WIDTH-1:0]      in_data,
    input  wire [SHIFT_WIDTH-1:0]     shift_amount,
    output wire [DATA_WIDTH-1:0]      out_data
);

    // Pipeline stage registers and wires
    wire   [DATA_WIDTH-1:0] pipeline_stage_data     [0:SHIFT_WIDTH];
    wire   [SHIFT_WIDTH-1:0] pipeline_stage_shift   [0:SHIFT_WIDTH];

    // Stage 0: Input register
    reg    [DATA_WIDTH-1:0]  reg_stage0_data;
    reg    [SHIFT_WIDTH-1:0] reg_stage0_shift;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_stage0_data  <= {DATA_WIDTH{1'b0}};
            reg_stage0_shift <= {SHIFT_WIDTH{1'b0}};
        end else begin
            reg_stage0_data  <= in_data;
            reg_stage0_shift <= shift_amount;
        end
    end
    assign pipeline_stage_data[0]   = reg_stage0_data;
    assign pipeline_stage_shift[0]  = reg_stage0_shift;

    // Pipeline stages for shifting
    genvar gi;
    generate
        for (gi = 0; gi < SHIFT_WIDTH; gi = gi + 1) begin : gen_pipeline_stages
            // Register for data path
            reg [DATA_WIDTH-1:0]  reg_stage_data;
            reg [SHIFT_WIDTH-1:0] reg_stage_shift;
            wire [DATA_WIDTH-1:0] stage_shifted_data;

            // Combinational logic for this stage
            pipelined_logical_right_shift_stage #(
                .DATA_WIDTH(DATA_WIDTH),
                .SHIFT_BITS(gi)
            ) u_shift_stage (
                .in_data    (pipeline_stage_data[gi]),
                .shift_en   (pipeline_stage_shift[gi][gi]),
                .out_data   (stage_shifted_data)
            );

            // Registering shifted data and passing down remaining shift_amount
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    reg_stage_data  <= {DATA_WIDTH{1'b0}};
                    reg_stage_shift <= {SHIFT_WIDTH{1'b0}};
                end else begin
                    reg_stage_data  <= stage_shifted_data;
                    reg_stage_shift <= pipeline_stage_shift[gi];
                end
            end

            assign pipeline_stage_data[gi+1]  = reg_stage_data;
            assign pipeline_stage_shift[gi+1] = reg_stage_shift;
        end
    endgenerate

    // Output assignment from final pipeline stage
    assign out_data = pipeline_stage_data[SHIFT_WIDTH];

endmodule

// --------------------------------------------------
// Submodule: pipelined_logical_right_shift_stage
// Description: Performs a right shift by (1 << SHIFT_BITS) if shift_en is asserted.
// Inserts zeros from the left. Pure combinational; register at parent.
// --------------------------------------------------
module pipelined_logical_right_shift_stage #(
    parameter DATA_WIDTH = 16,
    parameter SHIFT_BITS = 0
)(
    input  wire [DATA_WIDTH-1:0] in_data,
    input  wire                  shift_en,
    output wire [DATA_WIDTH-1:0] out_data
);

    localparam integer SHIFT_VAL = (1 << SHIFT_BITS);

    wire [DATA_WIDTH-1:0] shifted_data;
    assign shifted_data = { {SHIFT_VAL{1'b0}}, in_data[DATA_WIDTH-1:SHIFT_VAL] };
    assign out_data = shift_en ? shifted_data : in_data;

endmodule