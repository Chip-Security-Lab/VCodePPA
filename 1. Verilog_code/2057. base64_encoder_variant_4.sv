//SystemVerilog
// Top-level Base64 Encoder Module (Hierarchical)

module base64_encoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        data_valid,
    input  wire [7:0]  data_in,
    output wire [5:0]  base64_out,
    output wire        valid_out
);

    // Stage 1: Input Latch
    wire [7:0]  data_latched;
    wire        data_valid_latched;

    base64_input_latch u_input_latch (
        .clk               (clk),
        .rst_n             (rst_n),
        .data_in           (data_in),
        .data_valid_in     (data_valid),
        .data_out          (data_latched),
        .data_valid_out    (data_valid_latched)
    );

    // Stage 2: Input Buffer
    wire [15:0] buffer_out;
    wire        buffer_valid;

    base64_buffer u_buffer (
        .clk               (clk),
        .rst_n             (rst_n),
        .data_in           (data_latched),
        .data_valid_in     (data_valid_latched),
        .buffer_out        (buffer_out),
        .buffer_valid_out  (buffer_valid)
    );

    // Stage 3: Output Count and Buffer Propagation
    wire [1:0]  out_count;
    wire [15:0] buffer_stage3;
    wire        stage3_valid;

    base64_output_counter u_output_counter (
        .clk               (clk),
        .rst_n             (rst_n),
        .buffer_in         (buffer_out),
        .buffer_valid_in   (buffer_valid),
        .out_count         (out_count),
        .buffer_out        (buffer_stage3),
        .stage3_valid_out  (stage3_valid)
    );

    // Stage 4: Base64 Output Logic
    wire [5:0]  base64_data;
    wire        base64_valid;

    base64_output_logic u_output_logic (
        .clk               (clk),
        .rst_n             (rst_n),
        .buffer_in         (buffer_stage3),
        .out_count_in      (out_count),
        .stage3_valid_in   (stage3_valid),
        .base64_out        (base64_data),
        .valid_out         (base64_valid)
    );

    // Output Register Stage
    base64_output_register u_output_register (
        .clk               (clk),
        .rst_n             (rst_n),
        .base64_in         (base64_data),
        .valid_in          (base64_valid),
        .base64_out        (base64_out),
        .valid_out         (valid_out)
    );

endmodule

// -----------------------------------------------------------------------------
// Submodule: base64_input_latch
// Function: Latches the input data and valid signal on each clock cycle
// -----------------------------------------------------------------------------
module base64_input_latch (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire       data_valid_in,
    output reg  [7:0] data_out,
    output reg        data_valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out        <= 8'd0;
            data_valid_out  <= 1'b0;
        end else begin
            data_out        <= data_in;
            data_valid_out  <= data_valid_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: base64_buffer
// Function: Buffers incoming data, forms a 16-bit buffer and generates valid
// -----------------------------------------------------------------------------
module base64_buffer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        data_valid_in,
    output reg  [15:0] buffer_out,
    output reg         buffer_valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_out        <= 16'd0;
            buffer_valid_out  <= 1'b0;
        end else begin
            if (data_valid_in) begin
                buffer_out[15:8] <= data_in;
                buffer_out[7:0]  <= buffer_out[7:0];
                buffer_valid_out <= 1'b1;
            end else begin
                buffer_valid_out <= 1'b0;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: base64_output_counter
// Function: Maintains output count and propagates buffer for Base64 encoding
// -----------------------------------------------------------------------------
module base64_output_counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] buffer_in,
    input  wire        buffer_valid_in,
    output reg  [1:0]  out_count,
    output reg  [15:0] buffer_out,
    output reg         stage3_valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_count        <= 2'd0;
            buffer_out       <= 16'd0;
            stage3_valid_out <= 1'b0;
        end else begin
            if (buffer_valid_in) begin
                out_count        <= 2'd0;
                buffer_out       <= buffer_in;
                stage3_valid_out <= 1'b1;
            end else if (stage3_valid_out && out_count < 2'd3) begin
                out_count        <= out_count + 1'b1;
                buffer_out       <= buffer_out;
                stage3_valid_out <= 1'b1;
            end else begin
                stage3_valid_out <= 1'b0;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: base64_output_logic
// Function: Encodes buffer to Base64, generates output and valid signal
// -----------------------------------------------------------------------------
module base64_output_logic (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] buffer_in,
    input  wire [1:0]  out_count_in,
    input  wire        stage3_valid_in,
    output reg  [5:0]  base64_out,
    output reg         valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base64_out <= 6'd0;
            valid_out  <= 1'b0;
        end else begin
            if (stage3_valid_in) begin
                case (out_count_in)
                    2'd0: base64_out <= buffer_in[15:10];
                    2'd1: base64_out <= buffer_in[9:4];
                    2'd2: base64_out <= buffer_in[3:0] << 2;
                    default: base64_out <= 6'd0;
                endcase
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: base64_output_register
// Function: Registers the final Base64 output and valid signal for output
// -----------------------------------------------------------------------------
module base64_output_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [5:0] base64_in,
    input  wire       valid_in,
    output reg  [5:0] base64_out,
    output reg        valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            base64_out <= 6'd0;
            valid_out  <= 1'b0;
        end else begin
            base64_out <= base64_in;
            valid_out  <= valid_in;
        end
    end
endmodule