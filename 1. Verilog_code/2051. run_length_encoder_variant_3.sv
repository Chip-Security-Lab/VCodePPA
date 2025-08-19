//SystemVerilog
module run_length_encoder (
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    input wire data_in,
    output reg [7:0] count_out,
    output reg data_bit_out,
    output reg valid_out
);

    reg [7:0] counter_reg, counter_next;
    reg data_prev_reg, data_prev_next;
    reg emit_reg, emit_next;
    reg [7:0] count_out_next;
    reg data_bit_out_next;

    // Path-balanced combinational logic
    wire is_count_max, is_data_changed, is_emit_condition;
    assign is_count_max    = (counter_reg == 8'hFF);
    assign is_data_changed = (data_in != data_prev_reg);
    assign is_emit_condition = is_count_max | is_data_changed;

    always @* begin
        // Default assignments
        counter_next      = counter_reg;
        data_prev_next    = data_prev_reg;
        emit_next         = 1'b0;
        count_out_next    = count_out;
        data_bit_out_next = data_bit_out;

        if (data_valid) begin
            data_prev_next = data_in;
            if (is_emit_condition) begin
                // Emit current run
                emit_next         = 1'b1;
                count_out_next    = counter_reg;
                data_bit_out_next = data_prev_reg;
                counter_next      = 8'h1;
            end else begin
                // Continue current run
                counter_next = counter_reg + 8'h1;
            end
        end
    end

    // Sequential logic: update registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg      <= 8'h1;
            data_prev_reg    <= 1'b0;
            emit_reg         <= 1'b0;
            count_out        <= 8'h0;
            data_bit_out     <= 1'b0;
            valid_out        <= 1'b0;
        end else begin
            counter_reg      <= counter_next;
            data_prev_reg    <= data_prev_next;
            emit_reg         <= emit_next;
            count_out        <= count_out_next;
            data_bit_out     <= data_bit_out_next;
            valid_out        <= emit_reg;
        end
    end

endmodule