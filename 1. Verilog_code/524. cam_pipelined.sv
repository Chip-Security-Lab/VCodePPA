module cam_pipelined #(parameter WIDTH=8, DEPTH=256)(
    input clk,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(DEPTH)-1:0] match_addr,
    output reg match_valid
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    reg [DEPTH-1:0] stage1_hits;
    integer i, j;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        for(i=0; i<DEPTH; i=i+1)
            stage1_hits[i] <= (entries[i] == data_in);
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        match_valid <= |stage1_hits;
        match_addr <= 0;
        for(j=DEPTH-1; j>=0; j=j-1)
            if(stage1_hits[j]) match_addr <= j;
    end
endmodule