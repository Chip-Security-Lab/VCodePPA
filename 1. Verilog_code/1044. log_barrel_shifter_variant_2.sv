//SystemVerilog
// Top-level pipelined barrel shifter with structured datapath

module pipelined_barrel_shifter #(parameter WIDTH=32) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire [WIDTH-1:0]         in_data,
    input  wire [$clog2(WIDTH)-1:0] shift_amt,
    output wire [WIDTH-1:0]         out_data
);

    // Number of pipeline stages equals log2(WIDTH)
    localparam integer NUM_STAGES = $clog2(WIDTH);

    // Pipeline stage signals
    wire [WIDTH-1:0]                stage_data      [0:NUM_STAGES];
    wire [$clog2(WIDTH)-1:0]        stage_shift_amt [0:NUM_STAGES];
    reg  [WIDTH-1:0]                stage_data_reg  [0:NUM_STAGES-1];
    reg  [$clog2(WIDTH)-1:0]        stage_shift_reg [0:NUM_STAGES-1];

    // Input register (Stage 0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_data_reg[0]  <= {WIDTH{1'b0}};
            stage_shift_reg[0] <= {($clog2(WIDTH)){1'b0}};
        end else begin
            stage_data_reg[0]  <= in_data;
            stage_shift_reg[0] <= shift_amt;
        end
    end

    assign stage_data[0]      = stage_data_reg[0];
    assign stage_shift_amt[0] = stage_shift_reg[0];

    genvar i;
    generate
        for (i = 0; i < NUM_STAGES-1; i = i + 1) begin : gen_pipeline_regs
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_data_reg[i+1]  <= {WIDTH{1'b0}};
                    stage_shift_reg[i+1] <= {($clog2(WIDTH)){1'b0}};
                end else begin
                    stage_data_reg[i+1]  <= stage_data[i+1];
                    stage_shift_reg[i+1] <= stage_shift_amt[i+1];
                end
            end
            assign stage_data[i+1]      = stage_data_out[i];
            assign stage_shift_amt[i+1] = stage_shift_amt[i];
        end
    endgenerate

    // Barrel shift stages (combinational logic between pipeline registers)
    wire [WIDTH-1:0] stage_data_out [0:NUM_STAGES-1];

    generate
        for (i = 0; i < NUM_STAGES; i = i + 1) begin : gen_shift_stages
            pipelined_barrel_shift_stage #(
                .WIDTH(WIDTH),
                .SHIFT_AMOUNT(1 << i)
            ) u_pipelined_barrel_shift_stage (
                .data_in  (stage_data_reg[i]),
                .shift_en (stage_shift_reg[i][i]),
                .data_out (stage_data_out[i])
            );
        end
    endgenerate

    // Output assignment
    assign out_data = stage_data_reg[NUM_STAGES-1];

endmodule

// ---------------------------------------------------------------------
// pipelined_barrel_shift_stage
//  - Single pipeline stage for the barrel shifter
//  - Shifts input data left by SHIFT_AMOUNT if shift_en is high
// ---------------------------------------------------------------------
module pipelined_barrel_shift_stage #(
    parameter WIDTH = 32,
    parameter SHIFT_AMOUNT = 1
) (
    input  wire [WIDTH-1:0] data_in,
    input  wire             shift_en,
    output wire [WIDTH-1:0] data_out
);
    assign data_out = shift_en ? (data_in << SHIFT_AMOUNT) : data_in;
endmodule