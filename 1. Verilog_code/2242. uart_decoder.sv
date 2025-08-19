module uart_decoder #(parameter BAUD_RATE=9600) (
    input rx, clk,
    output reg [7:0] data,
    output reg parity_err
);
    reg [3:0] sample_cnt;
    wire mid_sample = (sample_cnt == 4'd7);
    always @(posedge clk) begin
        if(rx && sample_cnt < 15) sample_cnt <= sample_cnt + 1;
        else if(mid_sample) begin
            data <= {rx, data[7:1]};
            parity_err <= ^data ^ rx;
        end
    end
endmodule