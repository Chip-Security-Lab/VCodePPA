//SystemVerilog

// Shift Register Submodule (Pipelined)
// Stage 1: Input register for data_in
// Stage 2: Shift operation and output register
module shift_register_pipeline #(
    parameter W = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                valid_in,
    input  wire [W-1:0]        data_in,
    output reg  [W-1:0]        data_out,
    output reg                 valid_out
);
    reg [W-1:0] data_in_stage1;
    reg         valid_stage1;

    // Stage 1: Register input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= {W{1'b0}};
            valid_stage1   <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1   <= valid_in;
        end
    end

    // Stage 2: Shift and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out   <= {W{1'b0}};
            valid_out  <= 1'b0;
        end else begin
            data_out   <= {data_in_stage1[W-2:0], 1'b1};
            valid_out  <= valid_stage1;
        end
    end

endmodule

// Preset Multiplexer Submodule (Pipelined)
// Stage 1: Register inputs
// Stage 2: Multiplex and output register
module preset_mux_pipeline #(
    parameter W = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                valid_in,
    input  wire                preset,
    input  wire [W-1:0]        preset_val,
    input  wire [W-1:0]        shift_val,
    output reg  [W-1:0]        mux_out,
    output reg                 valid_out
);
    reg        preset_stage1;
    reg [W-1:0] preset_val_stage1;
    reg [W-1:0] shift_val_stage1;
    reg        valid_stage1;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            preset_stage1      <= 1'b0;
            preset_val_stage1  <= {W{1'b0}};
            shift_val_stage1   <= {W{1'b0}};
            valid_stage1       <= 1'b0;
        end else begin
            preset_stage1      <= preset;
            preset_val_stage1  <= preset_val;
            shift_val_stage1   <= shift_val;
            valid_stage1       <= valid_in;
        end
    end

    // Stage 2: Mux and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_out    <= {W{1'b0}};
            valid_out  <= 1'b0;
        end else begin
            mux_out    <= preset_stage1 ? preset_val_stage1 : shift_val_stage1;
            valid_out  <= valid_stage1;
        end
    end

endmodule

// Top-Level Shift with Preset Module (Pipelined)
module shift_preset_pipeline #(
    parameter W = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                start,
    input  wire                preset,
    input  wire [W-1:0]        preset_val,
    output wire [W-1:0]        dout,
    output wire                valid_out
);

    // Pipeline control signals
    reg  [W-1:0] dout_stage0;
    reg          valid_stage0;

    // Stage 0: Input register and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage0  <= {W{1'b0}};
            valid_stage0 <= 1'b0;
        end else if (start) begin
            dout_stage0  <= preset_val;
            valid_stage0 <= 1'b1;
        end else if (valid_out) begin
            dout_stage0  <= dout;
            valid_stage0 <= valid_out;
        end
    end

    // Stage 1-2: Shift Register Pipeline
    wire [W-1:0] shift_val_stage2;
    wire         valid_shift_stage2;

    shift_register_pipeline #(.W(W)) u_shift_register_pipeline (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_stage0),
        .data_in   (dout_stage0),
        .data_out  (shift_val_stage2),
        .valid_out (valid_shift_stage2)
    );

    // Stage 3-4: Preset Mux Pipeline
    wire [W-1:0] mux_out_stage4;
    wire         valid_mux_stage4;

    preset_mux_pipeline #(.W(W)) u_preset_mux_pipeline (
        .clk        (clk),
        .rst_n      (rst_n),
        .valid_in   (valid_shift_stage2),
        .preset     (preset),
        .preset_val (preset_val),
        .shift_val  (shift_val_stage2),
        .mux_out    (mux_out_stage4),
        .valid_out  (valid_mux_stage4)
    );

    // Output assignments
    assign dout      = mux_out_stage4;
    assign valid_out = valid_mux_stage4;

endmodule