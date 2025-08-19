//SystemVerilog
module dram_ctrl_temp_comp #(
    parameter BASE_REFRESH = 7800
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);
    reg [15:0] refresh_counter;
    wire [15:0] refresh_interval;
    wire [15:0] temp_adj = {8'b0, temperature} << 3 + {8'b0, temperature} << 1;
    wire refresh_req_next;
    
    assign refresh_interval = BASE_REFRESH + temp_adj;
    assign refresh_req_next = (refresh_counter >= refresh_interval);
    
    always @(posedge clk) begin
        refresh_counter <= refresh_req_next ? 16'd0 : refresh_counter + 16'd1;
        refresh_req <= refresh_req_next;
    end
endmodule