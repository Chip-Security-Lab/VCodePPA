module manchester_decoder (
    input wire clk, rst_n, sample_en,
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
        end else if (sample_en) begin
            case (state)
                2'b00: begin
                    prev_sample <= manchester_in;
                    state <= 2'b01;
                    valid_out <= 1'b0;
                end
                2'b01: begin
                    data_out <= (prev_sample == 1'b0 && manchester_in == 1'b1);
                    valid_out <= 1'b1;
                    state <= 2'b00;
                end
                default: state <= 2'b00;
            endcase
        end else valid_out <= 1'b0;
    end
endmodule