//SystemVerilog
//IEEE 1364-2005 Verilog standard
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
    // 优化的计数逻辑
    reg en_ff;
    wire [WIDTH-1:0] next_value;
    
    // 使用专用加法器结构实现计数
    assign next_value = cnt + {{(WIDTH-1){1'b0}}, 1'b1};
    
    always @(posedge clk) begin
        if (!rst_n) begin
            en_ff <= 1'b0;
            cnt <= {WIDTH{1'b0}};
        end else begin
            en_ff <= en;
            if (en_ff) cnt <= next_value;
        end
    end
endmodule