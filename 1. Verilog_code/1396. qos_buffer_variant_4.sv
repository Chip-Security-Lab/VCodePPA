//SystemVerilog
module qos_buffer #(parameter DW=32, N=4) (
    input clk, rst_n,
    input [N-1:0] wr_en,
    input [N*DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] mem [0:N-1];
    reg [DW-1:0] mem_buffered [0:N-1]; // Buffer registers for mem
    reg [1:0] ptr;
    reg [1:0] ptr_buffered; // Buffer register for ptr
    integer i;
    
    // Main memory update logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr <= 0;
            for(i=0; i<N; i=i+1)
                mem[i] <= 0;
        end
        else begin
            for(i=0; i<N; i=i+1)
                if(wr_en[i]) mem[i] <= din[i*DW +: DW];
            
            if(ptr == N-1)
                ptr <= 0;
            else
                ptr <= ptr + 1;
        end
    end
    
    // Buffer register stage for mem and ptr (to reduce fan-out)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr_buffered <= 0;
            for(i=0; i<N; i=i+1)
                mem_buffered[i] <= 0;
        end
        else begin
            ptr_buffered <= ptr;
            for(i=0; i<N; i=i+1)
                mem_buffered[i] <= mem[i];
        end
    end
    
    // Use buffered signals for output
    assign dout = mem_buffered[ptr_buffered];
endmodule