//SystemVerilog
// Top-level module: Hierarchical, pipelined MuxShiftRegister with functional submodules

module MuxShiftRegister_Pipelined #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  sel,
    input        [1:0]     serial_in,
    input                  valid_in,
    output      [WIDTH-1:0] data_out,
    output                 valid_out
);

    // Stage 1 pipeline registers
    wire                   sel_stage1;
    wire        [1:0]      serial_in_stage1;
    wire                   valid_stage1;

    // Stage 2 pipeline registers
    wire                   selected_bit_stage2;
    wire        [WIDTH-1:0] data_out_stage2;
    wire                   valid_stage2;

    // Stage 3 output registers
    wire        [WIDTH-1:0] data_out_stage3;
    wire                   valid_out_stage3;

    // Stage 1: Pipeline input signals
    MuxShiftRegister_Stage1 #(
        .WIDTH(WIDTH)
    ) u_stage1 (
        .clk            (clk),
        .rst_n          (rst_n),
        .sel_in         (sel),
        .serial_in_in   (serial_in),
        .valid_in       (valid_in),
        .sel_out        (sel_stage1),
        .serial_in_out  (serial_in_stage1),
        .valid_out      (valid_stage1)
    );

    // Stage 2: Mux select and data pipeline
    MuxShiftRegister_Stage2 #(
        .WIDTH(WIDTH)
    ) u_stage2 (
        .clk                (clk),
        .rst_n              (rst_n),
        .sel_in             (sel_stage1),
        .serial_in_in       (serial_in_stage1),
        .valid_in           (valid_stage1),
        .data_out_in        (data_out_stage3),
        .selected_bit_out   (selected_bit_stage2),
        .data_out_out       (data_out_stage2),
        .valid_out          (valid_stage2)
    );

    // Stage 3: Shift register update
    MuxShiftRegister_Stage3 #(
        .WIDTH(WIDTH)
    ) u_stage3 (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_out_stage2),
        .bit_in         (selected_bit_stage2),
        .valid_in       (valid_stage2),
        .data_out       (data_out_stage3),
        .valid_out      (valid_out_stage3)
    );

    // Output assignments
    assign data_out  = data_out_stage3;
    assign valid_out = valid_out_stage3;

endmodule

// -----------------------------------------------------------------------------
// Stage 1: Input Pipeline Register
// Captures and pipelines the select, serial_in and valid signals
// -----------------------------------------------------------------------------
module MuxShiftRegister_Stage1 #(
    parameter WIDTH = 8
)(
    input              clk,
    input              rst_n,
    input              sel_in,
    input      [1:0]   serial_in_in,
    input              valid_in,
    output reg         sel_out,
    output reg [1:0]   serial_in_out,
    output reg         valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel_out        <= 1'b0;
            serial_in_out  <= 2'b0;
            valid_out      <= 1'b0;
        end else begin
            sel_out        <= sel_in;
            serial_in_out  <= serial_in_in;
            valid_out      <= valid_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 2: Mux Select and Data Pipeline Register
// Selects the correct serial input bit, pipelines previous data_out, and valid
// -----------------------------------------------------------------------------
module MuxShiftRegister_Stage2 #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input                  sel_in,
    input        [1:0]     serial_in_in,
    input                  valid_in,
    input        [WIDTH-1:0] data_out_in,
    output reg             selected_bit_out,
    output reg [WIDTH-1:0] data_out_out,
    output reg             valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            selected_bit_out <= 1'b0;
            data_out_out     <= {WIDTH{1'b0}};
            valid_out        <= 1'b0;
        end else begin
            selected_bit_out <= serial_in_in[sel_in];
            data_out_out     <= data_out_in;
            valid_out        <= valid_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 3: Shift Register Update
// Shifts the register and updates valid signal
// -----------------------------------------------------------------------------
module MuxShiftRegister_Stage3 #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input        [WIDTH-1:0] data_in,
    input                  bit_in,
    input                  valid_in,
    output reg [WIDTH-1:0] data_out,
    output reg             valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (valid_in) begin
            data_out  <= {data_in[WIDTH-2:0], bit_in};
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule