//SystemVerilog
// Top-level: Hierarchical Parallel-to-Serial Converter

module parallel_to_serial #(
    parameter DATA_WIDTH = 8
)(
    input  wire                      clock,
    input  wire                      reset,
    input  wire                      load,
    input  wire [DATA_WIDTH-1:0]     parallel_data,
    output wire                      serial_out,
    output wire                      tx_done
);

    // Stage 1 signals
    wire [DATA_WIDTH-1:0]            s1_parallel_data;
    wire                             s1_load;
    wire                             s1_valid;

    // Stage 2 signals
    wire [DATA_WIDTH-1:0]            s2_shift_reg;
    wire [$clog2(DATA_WIDTH):0]      s2_bit_counter;
    wire                             s2_valid;

    // Stage 3 signals
    wire                             s3_serial_out;
    wire                             s3_tx_done;
    wire                             s3_valid;

    // Stage 1: Input Latch and Load Control
    parallel_to_serial_stage1 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) stage1_u (
        .clock          (clock),
        .reset          (reset),
        .parallel_data  (parallel_data),
        .load           (load),
        .stage1_data    (s1_parallel_data),
        .stage1_load    (s1_load),
        .stage1_valid   (s1_valid)
    );

    // Stage 2: Shift Register and Bit Counter
    parallel_to_serial_stage2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) stage2_u (
        .clock           (clock),
        .reset           (reset),
        .stage1_data     (s1_parallel_data),
        .stage1_load     (s1_load),
        .stage1_valid    (s1_valid),
        .shift_reg       (s2_shift_reg),
        .bit_counter     (s2_bit_counter),
        .stage2_valid    (s2_valid)
    );

    // Stage 3: Output Logic
    parallel_to_serial_stage3 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) stage3_u (
        .clock           (clock),
        .reset           (reset),
        .shift_reg       (s2_shift_reg),
        .bit_counter     (s2_bit_counter),
        .stage2_valid    (s2_valid),
        .serial_out      (s3_serial_out),
        .tx_done         (s3_tx_done),
        .stage3_valid    (s3_valid)
    );

    assign serial_out = s3_serial_out;
    assign tx_done    = s3_tx_done;

endmodule

// -----------------------------------------------------------------------------
// Stage 1: Input Latch and Load Control
// Captures parallel data and the load signal, and generates a valid flag
// -----------------------------------------------------------------------------
module parallel_to_serial_stage1 #(
    parameter DATA_WIDTH = 8
)(
    input  wire                      clock,
    input  wire                      reset,
    input  wire [DATA_WIDTH-1:0]     parallel_data,
    input  wire                      load,
    output reg  [DATA_WIDTH-1:0]     stage1_data,
    output reg                       stage1_load,
    output reg                       stage1_valid
);
    always @(posedge clock) begin
        if (reset) begin
            stage1_data  <= {DATA_WIDTH{1'b0}};
            stage1_load  <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data  <= parallel_data;
            stage1_load  <= load;
            stage1_valid <= 1'b1;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 2: Shift Register and Bit Counter
// Loads data on load, shifts data out, and counts the bits shifted
// -----------------------------------------------------------------------------
module parallel_to_serial_stage2 #(
    parameter DATA_WIDTH = 8
)(
    input  wire                      clock,
    input  wire                      reset,
    input  wire [DATA_WIDTH-1:0]     stage1_data,
    input  wire                      stage1_load,
    input  wire                      stage1_valid,
    output reg  [DATA_WIDTH-1:0]     shift_reg,
    output reg  [$clog2(DATA_WIDTH):0] bit_counter,
    output reg                       stage2_valid
);
    always @(posedge clock) begin
        if (reset) begin
            shift_reg   <= {DATA_WIDTH{1'b0}};
            bit_counter <= {($clog2(DATA_WIDTH)+1){1'b0}};
            stage2_valid<= 1'b0;
        end else begin
            if (stage1_load) begin
                shift_reg   <= stage1_data;
                bit_counter <= 1'b1;
            end else if (stage2_valid && (bit_counter > 0) && (bit_counter < (DATA_WIDTH+1))) begin
                shift_reg   <= {shift_reg[DATA_WIDTH-2:0], 1'b0};
                bit_counter <= bit_counter + 1'b1;
            end
            stage2_valid <= stage1_valid;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Stage 3: Output Logic
// Drives the serial output and transmission done flag
// -----------------------------------------------------------------------------
module parallel_to_serial_stage3 #(
    parameter DATA_WIDTH = 8
)(
    input  wire                      clock,
    input  wire                      reset,
    input  wire [DATA_WIDTH-1:0]     shift_reg,
    input  wire [$clog2(DATA_WIDTH):0] bit_counter,
    input  wire                      stage2_valid,
    output reg                       serial_out,
    output reg                       tx_done,
    output reg                       stage3_valid
);
    always @(posedge clock) begin
        if (reset) begin
            serial_out   <= 1'b0;
            tx_done      <= 1'b0;
            stage3_valid <= 1'b0;
        end else begin
            serial_out   <= shift_reg[DATA_WIDTH-1];
            tx_done      <= (bit_counter == DATA_WIDTH);
            stage3_valid <= stage2_valid;
        end
    end
endmodule