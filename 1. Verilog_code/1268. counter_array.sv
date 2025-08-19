module counter_array #(parameter NUM=4, WIDTH=4) (
    input clk, rst,
    output [NUM*WIDTH-1:0] cnts
);
    genvar i;
    generate
        for(i=0; i<NUM; i=i+1) begin : cnt
            counter_sync_inc #(WIDTH) u_cnt(
                .clk(clk),
                .rst_n(~rst),
                .en(1'b1),
                .cnt(cnts[i*WIDTH +: WIDTH])
            );
        end
    endgenerate
endmodule

module counter_sync_inc #(parameter WIDTH=4) (
    input clk, rst_n, en,
    output reg [WIDTH-1:0] cnt
);
    always @(posedge clk) begin
        if (!rst_n) cnt <= 0;
        else if (en) cnt <= cnt + 1;
    end
endmodule