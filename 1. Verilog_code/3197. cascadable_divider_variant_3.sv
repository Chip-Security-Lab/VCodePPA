//SystemVerilog
module cascadable_divider (
    input clk_in,
    input req_in,       // 替代原先的cascade_en，作为请求信号
    output reg clk_out,
    output reg ack_out  // 替代原先的cascade_out，作为应答信号
);
    reg [7:0] counter;
    reg req_received;
    
    always @(posedge clk_in) begin
        if (req_in && !req_received) begin
            req_received <= 1'b1;
            ack_out <= 1'b0;
        end
        
        if (req_received) begin
            if (counter == 8'd9) begin
                counter <= 8'd0;
                clk_out <= ~clk_out;
                ack_out <= 1'b1;
                req_received <= 1'b0;
            end else begin
                counter <= counter + 1'b1;
                ack_out <= 1'b0;
            end
        end
    end
endmodule