//SystemVerilog
module w2n_bridge #(parameter WIDE=32, NARROW=8) (
    input clk, rst_n,
    input [WIDE-1:0] wide_data,
    input wide_valid,
    output reg wide_ready,
    output reg [NARROW-1:0] narrow_data,
    output reg narrow_valid,
    input narrow_ready
);
    localparam RATIO = WIDE/NARROW;
    reg [WIDE-1:0] buffer;
    reg [$clog2(RATIO):0] count;
    reg [$clog2(RATIO):0] next_count;
    reg [NARROW-1:0] next_narrow_data;
    reg next_narrow_valid;
    reg next_wide_ready;

    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer <= 0; 
            count <= 0; 
            narrow_valid <= 0; 
            wide_ready <= 1;
        end else begin
            count <= next_count;
            narrow_data <= next_narrow_data;
            narrow_valid <= next_narrow_valid;
            wide_ready <= next_wide_ready;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_count = count;
        next_narrow_data = narrow_data;
        next_narrow_valid = narrow_valid;
        next_wide_ready = wide_ready;

        if (wide_valid && wide_ready && count == 0) begin
            buffer = wide_data;
            next_narrow_data = wide_data[NARROW-1:0];
            next_narrow_valid = 1;
            next_wide_ready = 0;
            next_count = 1;
        end

        if (narrow_valid && narrow_ready) begin
            if (count < RATIO) begin
                // Implementing two's complement subtraction
                next_narrow_data = buffer[count*NARROW +: NARROW] - (wide_data[NARROW-1:0] ^ {NARROW{1'b1}}) + 1; // Two's complement
                next_count = count + 1;
            end
            if (count == RATIO-1) begin
                next_count = 0;
                next_wide_ready = 1;
                next_narrow_valid = 0;
            end
        end
    end
endmodule