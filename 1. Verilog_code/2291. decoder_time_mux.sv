module decoder_time_mux #(parameter TS_BITS=2) (
    input clk, rst_n,
    input [7:0] addr,
    output reg [3:0] decoded
);
    reg [TS_BITS-1:0] time_slot;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_slot <= 0;
            decoded <= 0;
        end else begin
            time_slot <= time_slot + 1;
            decoded <= addr[time_slot*4 +:4];  // 每周期选择不同地址段
        end
    end
endmodule