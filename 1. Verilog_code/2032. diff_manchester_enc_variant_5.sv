//SystemVerilog
module diff_manchester_enc (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  encoded
);
    reg prev_encoded;
    reg data_in_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_encoded <= 1'b0;
            data_in_d    <= 1'b0;
            encoded      <= 1'b0;
        end else begin
            prev_encoded <= encoded;
            data_in_d    <= data_in;
            encoded      <= prev_encoded ^ data_in_d;
        end
    end

endmodule