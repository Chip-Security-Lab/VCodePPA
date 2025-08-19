module delta_encoder #(
    parameter WIDTH = 12
)(
    input                   clk_i,
    input                   en_i,
    input                   rst_i,
    input      [WIDTH-1:0]  data_i,
    output reg [WIDTH-1:0]  delta_o,
    output reg              valid_o
);
    reg [WIDTH-1:0] prev_sample;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            prev_sample <= 0;
            delta_o <= 0;
            valid_o <= 0;
        end else if (en_i) begin
            delta_o <= data_i - prev_sample;
            prev_sample <= data_i;
            valid_o <= 1'b1;
        end else begin
            valid_o <= 1'b0;
        end
    end
endmodule