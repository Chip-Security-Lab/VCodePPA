//SystemVerilog
module qos_buffer #(parameter DW=32, N=4) (
    input clk, rst_n,
    input [N-1:0] wr_en,
    input [N*DW-1:0] din,
    output [DW-1:0] dout
);
    // Memory array with buffered access
    reg [DW-1:0] mem [0:N-1];
    // Multi-stage pipeline registers for memory access
    reg [DW-1:0] mem_stage1 [0:N-1];
    reg [DW-1:0] mem_stage2 [0:N-1];
    reg [DW-1:0] mem_stage3 [0:N-1];
    
    // Pointer registers for different pipeline stages
    reg [1:0] ptr;
    reg [1:0] ptr_stage1;
    reg [1:0] ptr_stage2;
    
    integer i;
    
    // Stage 1: Buffer memory access
    always @(posedge clk) begin
        for(i=0; i<N; i=i+1)
            mem_stage1[i] <= mem[i];
        ptr_stage1 <= ptr;
    end
    
    // Stage 2: Additional buffering to break timing paths
    always @(posedge clk) begin
        for(i=0; i<N; i=i+1)
            mem_stage2[i] <= mem_stage1[i];
        ptr_stage2 <= ptr_stage1;
    end
    
    // Stage 3: Final output buffering
    always @(posedge clk) begin
        for(i=0; i<N; i=i+1)
            mem_stage3[i] <= mem_stage2[i];
    end
    
    // Memory write and pointer update logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr <= 0;
            for(i=0; i<N; i=i+1)
                mem[i] <= 0;
        end
        else begin
            // Split the write operations into separate conditions
            // to reduce logic depth per cycle
            for(i=0; i<N; i=i+1) begin
                if(wr_en[i]) 
                    mem[i] <= din[i*DW +: DW];
            end
            
            // Simplified pointer update logic
            if(ptr == N-1)
                ptr <= 0;
            else
                ptr <= ptr + 1;
        end
    end
    
    // Use deeply pipelined memory output to reduce critical path
    assign dout = mem_stage3[ptr_stage2];
endmodule