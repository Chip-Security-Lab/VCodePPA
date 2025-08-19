//SystemVerilog
module manchester_decoder (
    input wire clk,
    input wire rst_n,
    input wire sample_en,
    input wire manchester_in,
    output reg data_out,
    output reg valid_out
);
    reg prev_sample;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 2'b00;
            valid_out <= 1'b0;
            prev_sample <= 1'b0;
            data_out <= 1'b0;
        end else begin
            if (sample_en && (state == 2'b00)) begin
                prev_sample <= manchester_in;
                state <= 2'b01;
                valid_out <= 1'b0;
            end else if (sample_en && (state == 2'b01)) begin
                data_out <= (prev_sample == 1'b0 && manchester_in == 1'b1);
                valid_out <= 1'b1;
                state <= 2'b00;
            end else if (sample_en && (state != 2'b00) && (state != 2'b01)) begin
                state <= 2'b00;
            end else if (!sample_en) begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule