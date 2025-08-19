module dram_ctrl_temp_comp #(
    parameter BASE_REFRESH = 7800
)(
    input clk,
    input [7:0] temperature,
    output reg refresh_req
);
    reg [15:0] refresh_counter;
    wire [15:0] refresh_interval = BASE_REFRESH + (temperature * 10);
    
    always @(posedge clk) begin
        if(refresh_counter >= refresh_interval) begin
            refresh_req <= 1;
            refresh_counter <= 0;
        end else begin
            refresh_req <= 0;
            refresh_counter <= refresh_counter + 1;
        end
    end
endmodule

