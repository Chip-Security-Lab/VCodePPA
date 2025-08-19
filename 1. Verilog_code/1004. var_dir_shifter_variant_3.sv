//SystemVerilog
// Top-level variable direction shifter module with Valid-Ready handshake

module var_dir_shifter(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [15:0]  in_data,
    input  wire [3:0]   shift_amount,
    input  wire         direction,       // 0: right, 1: left
    input  wire         fill_value,      // Value to fill vacant bits
    input  wire         in_valid,
    output wire         in_ready,
    output wire [15:0]  out_data,
    output wire         out_valid,
    input  wire         out_ready
);

    // Internal signals
    reg  [15:0] in_data_reg;
    reg  [3:0]  shift_amount_reg;
    reg         direction_reg;
    reg         fill_value_reg;
    reg         data_buffered;
    reg         handshake_done;

    wire [15:0] left_shifted_data;
    wire [15:0] right_shifted_data;
    wire        output_enable;

    // Valid-Ready handshake for input
    assign in_ready = ~data_buffered | (handshake_done & out_ready);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_reg      <= 16'd0;
            shift_amount_reg <= 4'd0;
            direction_reg    <= 1'b0;
            fill_value_reg   <= 1'b0;
            data_buffered    <= 1'b0;
        end else if (in_valid && in_ready) begin
            in_data_reg      <= in_data;
            shift_amount_reg <= shift_amount;
            direction_reg    <= direction;
            fill_value_reg   <= fill_value;
            data_buffered    <= 1'b1;
        end else if (handshake_done && out_ready) begin
            data_buffered    <= 1'b0;
        end
    end

    // Left shift submodule instance
    left_var_shifter #(
        .DATA_WIDTH(16)
    ) u_left_var_shifter (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_data     (in_data_reg),
        .shift_amount(shift_amount_reg),
        .fill_value  (fill_value_reg),
        .in_valid    (data_buffered && direction_reg),
        .in_ready    (),
        .out_data    (left_shifted_data),
        .out_valid   ()
    );

    // Right shift submodule instance
    right_var_shifter #(
        .DATA_WIDTH(16)
    ) u_right_var_shifter (
        .clk         (clk),
        .rst_n       (rst_n),
        .in_data     (in_data_reg),
        .shift_amount(shift_amount_reg),
        .fill_value  (fill_value_reg),
        .in_valid    (data_buffered && ~direction_reg),
        .in_ready    (),
        .out_data    (right_shifted_data),
        .out_valid   ()
    );

    // Output mux and handshake
    reg [15:0] out_data_reg;
    reg        out_valid_reg;

    assign output_enable = data_buffered && ((direction_reg && in_valid) || (~direction_reg && in_valid));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data_reg  <= 16'd0;
            out_valid_reg <= 1'b0;
            handshake_done <= 1'b0;
        end else if (data_buffered && !out_valid_reg) begin
            out_data_reg  <= direction_reg ? left_shifted_data : right_shifted_data;
            out_valid_reg <= 1'b1;
            handshake_done <= 1'b1;
        end else if (out_valid_reg && out_ready) begin
            out_data_reg  <= 16'd0;
            out_valid_reg <= 1'b0;
            handshake_done <= 1'b0;
        end
    end

    assign out_data  = out_data_reg;
    assign out_valid = out_valid_reg;

endmodule

// -----------------------------------------------------------------------------
// Left Variable Shifter with Valid-Ready handshake
// -----------------------------------------------------------------------------
module left_var_shifter #(
    parameter DATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [DATA_WIDTH-1:0]     in_data,
    input  wire [$clog2(DATA_WIDTH):0] shift_amount,
    input  wire                      fill_value,
    input  wire                      in_valid,
    output wire                      in_ready,
    output reg  [DATA_WIDTH-1:0]     out_data,
    output reg                       out_valid
);
    reg  [DATA_WIDTH-1:0] shift_result;
    integer i;
    reg   busy;

    assign in_ready = !busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data  <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
            shift_result <= {DATA_WIDTH{1'b0}};
            busy <= 1'b0;
        end else if (in_valid && in_ready) begin
            shift_result = in_data;
            for (i = 0; i < shift_amount; i = i + 1) begin
                shift_result = {shift_result[DATA_WIDTH-2:0], fill_value};
            end
            out_data  <= shift_result;
            out_valid <= 1'b1;
            busy <= 1'b1;
        end else if (out_valid) begin
            out_valid <= 1'b0;
            busy <= 1'b0;
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Right Variable Shifter with Valid-Ready handshake
// -----------------------------------------------------------------------------
module right_var_shifter #(
    parameter DATA_WIDTH = 16
)(
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire [DATA_WIDTH-1:0]     in_data,
    input  wire [$clog2(DATA_WIDTH):0] shift_amount,
    input  wire                      fill_value,
    input  wire                      in_valid,
    output wire                      in_ready,
    output reg  [DATA_WIDTH-1:0]     out_data,
    output reg                       out_valid
);
    reg  [DATA_WIDTH-1:0] shift_result;
    integer i;
    reg   busy;

    assign in_ready = !busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data  <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
            shift_result <= {DATA_WIDTH{1'b0}};
            busy <= 1'b0;
        end else if (in_valid && in_ready) begin
            shift_result = in_data;
            for (i = 0; i < shift_amount; i = i + 1) begin
                shift_result = {fill_value, shift_result[DATA_WIDTH-1:1]};
            end
            out_data  <= shift_result;
            out_valid <= 1'b1;
            busy <= 1'b1;
        end else if (out_valid) begin
            out_valid <= 1'b0;
            busy <= 1'b0;
        end
    end

endmodule