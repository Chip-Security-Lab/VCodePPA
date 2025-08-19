//SystemVerilog
module counter_array #(parameter NUM=4, WIDTH=4) (
    input clk, rst,
    output [NUM*WIDTH-1:0] cnts
);
    // Optimized reset distribution network
    reg [NUM-1:0] rst_dist;
    
    // Distributed reset buffering for better fanout control
    always @(posedge clk) begin
        rst_dist[0] <= rst;
        for(int j=1; j<NUM; j=j+1) begin
            rst_dist[j] <= rst_dist[j-1];
        end
    end
    
    // Use balanced tree structure for counters
    genvar i;
    generate
        for(i=0; i<NUM; i=i+1) begin : cnt_block
            // Each counter uses dedicated reset buffer to reduce load
            counter_sync_inc #(WIDTH) u_cnt(
                .clk(clk),
                .rst_n(~rst_dist[i/(NUM/2)]),
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
    // Optimized counter logic with range check
    always @(posedge clk) begin
        if (!rst_n) 
            cnt <= {WIDTH{1'b0}};
        else if (en) begin
            // Optimized increment logic
            if (&cnt)
                cnt <= {WIDTH{1'b0}};
            else
                cnt <= cnt + 1'b1;
        end
    end
endmodule