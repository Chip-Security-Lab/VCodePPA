//SystemVerilog
module RLE_Encoder (
    input clk,
    input rst_n,
    input en,
    input [7:0] data_in,
    output reg [15:0] data_out,
    output reg req,
    input ack
);

reg [7:0] prev_data;
reg [7:0] counter;
reg data_ready;
reg prev_ack;
wire counter_at_max;
wire data_match;
wire handshake_complete;

// 优化的比较逻辑
assign counter_at_max = (counter == 8'hFF);
assign data_match = (data_in == prev_data);
assign handshake_complete = req && ack && !prev_ack;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prev_data <= 8'h0;
        counter <= 8'h0;
        data_out <= 16'h0;
        req <= 1'b0;
        data_ready <= 1'b0;
        prev_ack <= 1'b0;
    end else if (en) begin
        prev_ack <= ack;
        
        // 优化后的比较链
        if (data_match && !counter_at_max) begin
            counter <= counter + 8'h1;
        end else if (!req || (req && ack)) begin
            data_out <= {counter, prev_data};
            prev_data <= data_in;
            counter <= 8'h1;
            data_ready <= 1'b1;
        end
        
        // 优化请求逻辑
        if (data_ready && (!req || (req && ack))) begin
            req <= 1'b1;
            data_ready <= 1'b0;
        end else if (handshake_complete) begin
            req <= 1'b0;
        end
    end
end

endmodule