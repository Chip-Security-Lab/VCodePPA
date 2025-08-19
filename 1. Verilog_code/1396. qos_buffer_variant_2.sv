//SystemVerilog
module qos_buffer #(parameter DW=32, N=4) (
    input clk, rst_n,
    input [N-1:0] wr_en,
    input [N*DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] mem [0:N-1];
    reg [1:0] ptr, ptr_next, ptr_r;
    reg [DW-1:0] dout_r;
    integer i;
    
    // 预计算下一个指针值，减少关键路径延迟
    always @(*) begin
        ptr_next = (ptr == N-1) ? 2'b00 : ptr + 1'b1;
    end
    
    // Stage 1: Memory write and pointer update - 优化路径
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr <= 0;
            for(i=0; i<N; i=i+1)
                mem[i] <= 0;
        end
        else begin
            ptr <= ptr_next;
            
            // 分解写入逻辑，消除循环内的条件判断
            if(wr_en[0]) mem[0] <= din[0 +: DW];
            if(wr_en[1]) mem[1] <= din[DW +: DW];
            if(wr_en[2]) mem[2] <= din[2*DW +: DW];
            if(wr_en[3]) mem[3] <= din[3*DW +: DW];
        end
    end
    
    // Stage 2: Pipeline register for pointer
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr_r <= 0;
        end
        else begin
            ptr_r <= ptr;
        end
    end
    
    // Stage 3: Pipeline register for data output
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout_r <= 0;
        end
        else begin
            dout_r <= mem[ptr_r];
        end
    end
    
    // Final output
    assign dout = dout_r;
endmodule