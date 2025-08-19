//SystemVerilog
// Top-level module: Hierarchical Serial Shifter
module serial_shifter(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [1:0]  mode,       // 00:hold, 01:left, 10:right, 11:load
    input  wire [7:0]  data_in,
    input  wire        serial_in,
    output wire [7:0]  data_out
);

    wire [7:0] shift_result;
    wire [7:0] load_result;
    wire [7:0] mux_out;

    // Shift operation submodule
    shifter_unit u_shifter_unit (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (data_out_reg),
        .serial_in (serial_in),
        .mode      (mode),
        .shift_out (shift_result)
    );

    // Load operation submodule
    loader_unit u_loader_unit (
        .data_in   (data_in),
        .mode      (mode),
        .load_out  (load_result)
    );

    // Output multiplexer submodule
    output_mux u_output_mux (
        .hold_value (data_out_reg),
        .shift_value(shift_result),
        .load_value (load_result),
        .mode       (mode),
        .mux_out    (mux_out)
    );

    // Output register
    reg [7:0] data_out_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out_reg <= 8'h00;
        else if (enable)
            data_out_reg <= mux_out;
    end

    assign data_out = data_out_reg;

endmodule

// -----------------------------------------------------------------------------
// Submodule: shifter_unit
// Performs left or right shift based on mode using shift-add multiplication
// -----------------------------------------------------------------------------
module shifter_unit(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        serial_in,
    input  wire [1:0]  mode,
    output reg  [7:0]  shift_out
);
    reg [7:0] shift_reg;
    reg [2:0] shift_counter;
    reg       shifting;
    reg [7:0] serial_in_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg      <= 8'd0;
            shift_counter  <= 3'd0;
            shifting       <= 1'b0;
            serial_in_reg  <= 1'b0;
            shift_out      <= 8'd0;
        end else begin
            serial_in_reg <= serial_in;
            case (mode)
                2'b01: begin // Left shift (Shift-Add)
                    if (!shifting) begin
                        shift_reg     <= data_in;
                        shift_counter <= 3'd0;
                        shifting      <= 1'b1;
                    end else if (shifting && shift_counter < 3'd7) begin
                        shift_reg     <= {shift_reg[6:0], serial_in_reg};
                        shift_counter <= shift_counter + 1'b1;
                    end else if (shift_counter == 3'd7) begin
                        shift_out     <= {shift_reg[6:0], serial_in_reg};
                        shifting      <= 1'b0;
                    end
                end
                2'b10: begin // Right shift (Shift-Add)
                    if (!shifting) begin
                        shift_reg     <= data_in;
                        shift_counter <= 3'd0;
                        shifting      <= 1'b1;
                    end else if (shifting && shift_counter < 3'd7) begin
                        shift_reg     <= {serial_in_reg, shift_reg[7:1]};
                        shift_counter <= shift_counter + 1'b1;
                    end else if (shift_counter == 3'd7) begin
                        shift_out     <= {serial_in_reg, shift_reg[7:1]};
                        shifting      <= 1'b0;
                    end
                end
                default: begin
                    shift_out <= data_in;
                    shifting  <= 1'b0;
                end
            endcase
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: loader_unit
// Loads parallel data when mode is 2'b11
// -----------------------------------------------------------------------------
module loader_unit(
    input  wire [7:0] data_in,
    input  wire [1:0] mode,
    output reg  [7:0] load_out
);
    always @(*) begin
        if (mode == 2'b11)
            load_out = data_in;
        else
            load_out = 8'h00;
    end
endmodule

// -----------------------------------------------------------------------------
// Submodule: output_mux
// Selects the next value for the output register
// -----------------------------------------------------------------------------
module output_mux(
    input  wire [7:0] hold_value,
    input  wire [7:0] shift_value,
    input  wire [7:0] load_value,
    input  wire [1:0] mode,
    output reg  [7:0] mux_out
);
    always @(*) begin
        case (mode)
            2'b00: mux_out = hold_value;   // Hold
            2'b01: mux_out = shift_value;  // Left shift
            2'b10: mux_out = shift_value;  // Right shift
            2'b11: mux_out = load_value;   // Load
            default: mux_out = hold_value;
        endcase
    end
endmodule