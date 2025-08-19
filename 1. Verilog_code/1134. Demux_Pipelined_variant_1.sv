//SystemVerilog
// Top-level module
module Demux_Pipelined #(
    parameter DW = 16,    // Data width
    parameter STAGES = 2  // Number of output stages
) (
    input                           clk,
    input      [DW-1:0]             data_in,
    input      [$clog2(STAGES)-1:0] stage_sel,
    output     [STAGES-1:0][DW-1:0] pipe_out
);

    // Registered input data and selection signal
    reg [DW-1:0] data_in_reg;
    reg [$clog2(STAGES)-1:0] stage_sel_reg;
    
    always @(posedge clk) begin
        data_in_reg <= data_in;
        stage_sel_reg <= stage_sel;
    end

    wire [STAGES-1:0] stage_decode;
    
    // Instantiate decoder module with registered select input
    StageDecoder #(
        .STAGES(STAGES)
    ) stage_decoder_inst (
        .stage_sel(stage_sel_reg),
        .stage_decode(stage_decode)
    );

    // Instantiate optimized data demux module
    DataDemux #(
        .DW(DW),
        .STAGES(STAGES)
    ) data_demux_inst (
        .clk(clk),
        .data_in(data_in_reg),
        .stage_decode(stage_decode),
        .pipe_out(pipe_out)
    );

endmodule

// Decoder module for stage selection
module StageDecoder #(
    parameter STAGES = 2
) (
    input      [$clog2(STAGES)-1:0] stage_sel,
    output reg [STAGES-1:0]         stage_decode
);

    always @(*) begin
        stage_decode = 0;
        stage_decode[stage_sel] = 1'b1;
    end

endmodule

// Data demultiplexer module with integrated output registers
module DataDemux #(
    parameter DW = 16,
    parameter STAGES = 2
) (
    input                       clk,
    input  [DW-1:0]             data_in,
    input  [STAGES-1:0]         stage_decode,
    output reg [STAGES-1:0][DW-1:0] pipe_out
);

    // Intermediate demuxed data
    wire [STAGES-1:0][DW-1:0] demuxed_data;

    genvar i;
    generate
        for (i = 0; i < STAGES; i = i + 1) begin : gen_demux
            // Combinational demuxing logic
            assign demuxed_data[i] = stage_decode[i] ? data_in : {DW{1'b0}};
            
            // Registers moved closer to data source for each output path
            always @(posedge clk) begin
                pipe_out[i] <= demuxed_data[i];
            end
        end
    endgenerate

endmodule