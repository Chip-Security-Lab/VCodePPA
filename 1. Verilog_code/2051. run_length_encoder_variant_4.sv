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

    reg [7:0] counter_reg;
    reg data_prev_reg;

    reg [7:0] count_out_next;
    reg data_bit_out_next;
    reg valid_out_next;
    reg [7:0] counter_next;
    reg data_prev_next;

    // Combinational logic after input, before registers (retimed)
    always @(*) begin
        // Default assignments
        counter_next = counter_reg;
        data_prev_next = data_prev_reg;
        count_out_next = count_out;
        data_bit_out_next = data_bit_out;
        valid_out_next = 1'b0;

        if (data_valid) begin
            if (counter_reg == 8'hFF || data_in != data_prev_reg) begin
                // Output previous run
                count_out_next = counter_reg;
                data_bit_out_next = data_prev_reg;
                valid_out_next = 1'b1;
                counter_next = 8'h1;
            end else begin
                // Continue counting run
                counter_next = counter_reg + 1'b1;
                valid_out_next = 1'b0;
            end
            data_prev_next = data_in;
        end
    end

    // Registers after combinational logic (retimed)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= 8'h1;
            data_prev_reg <= 1'b0;
            count_out <= 8'h0;
            data_bit_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            data_prev_reg <= data_prev_next;
            count_out <= count_out_next;
            data_bit_out <= data_bit_out_next;
            valid_out <= valid_out_next;
        end
    end

endmodule