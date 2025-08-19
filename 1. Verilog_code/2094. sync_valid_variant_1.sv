//SystemVerilog
// Top-level module: Optimized hierarchical synchronization and valid signal generator (reduced pipeline depth)

module sync_valid_top #(parameter DW=16, STAGES=2) (
    input  wire               clkA,
    input  wire               clkB,
    input  wire               rst,
    input  wire [DW-1:0]      data_in,
    output wire [DW-1:0]      data_out,
    output wire               valid_out
);

    // Internal signals for inter-module connections
    wire [STAGES-1:0]         valid_sync_stage;
    wire                      valid_sync_full;
    wire [DW-1:0]             latched_data_stage;

    //-------------------------------------------------------------------------------
    // Valid Bit Synchronizer and Data Latch: Merged for reduced pipeline depth
    //-------------------------------------------------------------------------------
    valid_bit_synchronizer_and_latch #(
        .DW(DW),
        .STAGES(STAGES)
    ) u_valid_bit_synchronizer_and_latch (
        .clkB(clkB),
        .rst(rst),
        .data_in(data_in),
        .valid_in(data_in[0]),
        .valid_sync_stage(valid_sync_stage),
        .valid_sync_full(valid_sync_full),
        .latched_data_stage(latched_data_stage)
    );

    //-------------------------------------------------------------------------------
    // Output Register: Holds the output data and valid signal
    //-------------------------------------------------------------------------------
    output_register #(
        .DW(DW)
    ) u_output_register (
        .clkB(clkB),
        .rst(rst),
        .data_in(latched_data_stage),
        .valid_in(valid_sync_full),
        .data_out(data_out),
        .valid_out(valid_out)
    );

endmodule

//------------------------------------------------------------------------------
// Submodule: valid_bit_synchronizer_and_latch
// Function: Synchronizes the valid bit and latches data in a single stage
//------------------------------------------------------------------------------
module valid_bit_synchronizer_and_latch #(parameter DW=16, STAGES=2) (
    input  wire                clkB,
    input  wire                rst,
    input  wire [DW-1:0]       data_in,
    input  wire                valid_in,
    output reg  [STAGES-1:0]   valid_sync_stage,
    output wire                valid_sync_full,
    output reg  [DW-1:0]       latched_data_stage
);
    assign valid_sync_full = (valid_sync_stage == {STAGES{1'b1}});

    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            valid_sync_stage    <= {STAGES{1'b0}};
            latched_data_stage  <= {DW{1'b0}};
        end else begin
            valid_sync_stage    <= {valid_sync_stage[STAGES-2:0], valid_in};
            if ({valid_sync_stage[STAGES-2:0], valid_in} == {STAGES{1'b1}})
                latched_data_stage <= data_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// Submodule: output_register
// Function: Registers the final output data and valid flag
//------------------------------------------------------------------------------
module output_register #(parameter DW=16) (
    input  wire             clkB,
    input  wire             rst,
    input  wire [DW-1:0]    data_in,
    input  wire             valid_in,
    output reg  [DW-1:0]    data_out,
    output reg              valid_out
);
    always @(posedge clkB or posedge rst) begin
        if (rst) begin
            data_out  <= {DW{1'b0}};
            valid_out <= 1'b0;
        end else begin
            data_out  <= data_in;
            valid_out <= valid_in;
        end
    end
endmodule