//SystemVerilog
module serial_to_parallel #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire serial_in,
    output reg [WIDTH-1:0] parallel_out,
    output reg done
);

    // Counter for the received bits
    reg [$clog2(WIDTH):0] bit_counter;
    // Register to hold the sampled serial input
    reg serial_in_reg;

    // Combinational signals for next state logic
    wire [WIDTH-1:0] next_parallel_out;
    wire [$clog2(WIDTH):0] next_bit_counter;
    wire next_done;

    assign next_parallel_out = (bit_counter == WIDTH) ? {WIDTH{1'b0}} : {parallel_out[WIDTH-2:0], serial_in_reg};
    assign next_bit_counter  = (bit_counter == WIDTH) ? 0 : bit_counter + 1'b1;
    assign next_done         = (bit_counter == WIDTH);

    // -------------------------------------------------------------
    // Serial Input Sampling
    // -------------------------------------------------------------
    // Samples serial_in into serial_in_reg when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_reg <= 1'b0;
        end else if (en) begin
            serial_in_reg <= serial_in;
        end
    end

    // -------------------------------------------------------------
    // Bit Counter Logic
    // -------------------------------------------------------------
    // Handles bit counting for serial-to-parallel conversion
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 0;
        end else if (en) begin
            bit_counter <= next_bit_counter;
        end
    end

    // -------------------------------------------------------------
    // Parallel Output Register Logic
    // -------------------------------------------------------------
    // Shifts in serial input and forms parallel output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end else if (en) begin
            parallel_out <= next_parallel_out;
        end
    end

    // -------------------------------------------------------------
    // Done Signal Logic
    // -------------------------------------------------------------
    // Indicates when a parallel word has been fully received
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 1'b0;
        end else if (en) begin
            done <= next_done;
        end
    end

endmodule