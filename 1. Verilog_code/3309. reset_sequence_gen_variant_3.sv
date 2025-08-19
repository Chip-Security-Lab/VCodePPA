//SystemVerilog
// Top-level reset sequence generator module
module reset_sequence_gen(
    input  wire        clk,
    input  wire        trigger_reset,
    input  wire        config_mode,
    input  wire [1:0]  sequence_select,
    output wire        core_rst,
    output wire        periph_rst,
    output wire        mem_rst,
    output wire        io_rst,
    output wire        sequence_done
);

    // Internal signals for control and state
    wire        seq_active;
    wire [2:0]  seq_counter;
    wire        seq_start;
    wire        seq_done;
    wire [3:0]  rst_signals;

    // Control submodule: Handles sequence activation, counter, and done logic
    reset_sequence_ctrl u_reset_sequence_ctrl (
        .clk           (clk),
        .trigger_reset (trigger_reset),
        .seq_active    (seq_active),
        .seq_counter   (seq_counter),
        .sequence_done (seq_done)
    );

    // Pattern generator submodule: Generates reset patterns based on state
    reset_pattern_gen u_reset_pattern_gen (
        .seq_active      (seq_active),
        .seq_counter     (seq_counter),
        .sequence_select (sequence_select),
        .core_rst        (rst_signals[3]),
        .periph_rst      (rst_signals[2]),
        .mem_rst         (rst_signals[1]),
        .io_rst          (rst_signals[0])
    );

    assign {core_rst, periph_rst, mem_rst, io_rst} = rst_signals;
    assign sequence_done = seq_done;

endmodule

// -----------------------------------------------------------------------------
// Control logic submodule for sequence activation, counting, and done signaling
// -----------------------------------------------------------------------------
module reset_sequence_ctrl(
    input  wire       clk,
    input  wire       trigger_reset,
    output reg        seq_active,
    output reg [2:0]  seq_counter,
    output reg        sequence_done
);
    always @(posedge clk) begin
        if (trigger_reset && !seq_active) begin
            seq_active     <= 1'b1;
            seq_counter    <= 3'd0;
            sequence_done  <= 1'b0;
        end else if (seq_active) begin
            seq_counter <= seq_counter + 1'b1;
            if (seq_counter == 3'd7) begin
                seq_active    <= 1'b0;
                sequence_done <= 1'b1;
            end
        end else begin
            sequence_done <= 1'b0;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// Pattern generator submodule for reset signals based on sequence type/state
// -----------------------------------------------------------------------------
module reset_pattern_gen(
    input  wire        seq_active,
    input  wire [2:0]  seq_counter,
    input  wire [1:0]  sequence_select,
    output reg         core_rst,
    output reg         periph_rst,
    output reg         mem_rst,
    output reg         io_rst
);
    reg [3:0] rst_vector;
    always @(*) begin
        if (seq_active) begin
            case (sequence_select)
                2'b00: begin
                    // Range check for efficiency
                    if (seq_counter < 3'd2)
                        rst_vector = 4'b1111;
                    else if ((seq_counter >= 3'd2) && (seq_counter < 3'd4))
                        rst_vector = 4'b0111;
                    else if ((seq_counter >= 3'd4) && (seq_counter < 3'd6))
                        rst_vector = 4'b0011;
                    else
                        rst_vector = 4'b0000;
                end
                2'b01: begin
                    if (seq_counter < 3'd3)
                        rst_vector = 4'b1111;
                    else if ((seq_counter >= 3'd3) && (seq_counter < 3'd5))
                        rst_vector = 4'b0101;
                    else
                        rst_vector = 4'b0000;
                end
                default: begin
                    rst_vector = {4{seq_active}};
                end
            endcase
        end else begin
            rst_vector = 4'b0000;
        end
        {core_rst, periph_rst, mem_rst, io_rst} = rst_vector;
    end
endmodule