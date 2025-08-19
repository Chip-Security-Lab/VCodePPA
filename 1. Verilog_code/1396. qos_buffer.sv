module qos_buffer #(parameter DW=32, N=4) (
    input clk, rst_n,
    input [N-1:0] wr_en,
    input [N*DW-1:0] din,
    output [DW-1:0] dout
);
    reg [DW-1:0] mem [0:N-1];
    reg [1:0] ptr;
    integer i;
    
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
    assign dout = mem[ptr];
endmodule