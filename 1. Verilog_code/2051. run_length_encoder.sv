module run_length_encoder (
    input wire clk, rst_n, data_valid,
    input wire data_in,
    output reg [7:0] count_out,
    output reg data_bit_out,
    output reg valid_out
);
    reg data_prev;
    reg [7:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'h1;
            data_prev <= 1'b0;
            valid_out <= 1'b0;
        end else if (data_valid) begin
            if (counter == 8'hFF || data_in != data_prev) begin
                count_out <= counter;
                data_bit_out <= data_prev;
                valid_out <= 1'b1;
                counter <= 8'h1;
            end else begin
                counter <= counter + 1'b1;
                valid_out <= 1'b0;
            end
            data_prev <= data_in;
        end else valid_out <= 1'b0;
    end
endmodule