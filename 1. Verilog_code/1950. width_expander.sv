module width_expander #(
    parameter IN_WIDTH = 8,
    parameter OUT_WIDTH = 32  // 必须是IN_WIDTH的整数倍
)(
    input clk, rst, valid_in,
    input [IN_WIDTH-1:0] data_in,
    output reg [OUT_WIDTH-1:0] data_out,
    output reg valid_out
);
    localparam RATIO = OUT_WIDTH / IN_WIDTH;
    reg [$clog2(RATIO)-1:0] count;
    reg [OUT_WIDTH-1:0] buffer;
    
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            buffer <= 0;
            valid_out <= 0;
        end else if (valid_in) begin
            buffer <= {buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
            if (count == RATIO-1) begin
                count <= 0;
                data_out <= {buffer[OUT_WIDTH-IN_WIDTH-1:0], data_in};
                valid_out <= 1;
            end else begin
                count <= count + 1;
                valid_out <= 0;
            end
        end else begin
            valid_out <= 0;
        end
    end
endmodule