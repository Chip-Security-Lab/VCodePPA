//SystemVerilog
module qos_buffer #(parameter DW=32, N=4) (
    input clk, rst_n,
    input [N-1:0] wr_en,
    input [N*DW-1:0] din,
    output [DW-1:0] dout
);
    // Memory array
    reg [DW-1:0] mem [0:N-1];
    
    // Pipeline registers for pointer calculation
    reg [$clog2(N)-1:0] ptr_curr;
    reg [$clog2(N)-1:0] ptr_next;
    
    // Pipeline register for output data
    reg [DW-1:0] dout_reg;
    
    // Next pointer calculation logic - separated into its own stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr_next <= '0;
        end
        else begin
            // Pipelined pointer update logic
            ptr_next <= (ptr_curr == N-1) ? '0 : ptr_curr + 1'b1;
        end
    end
    
    // Memory operations and current pointer update
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ptr_curr <= '0;
            for(int i=0; i<N; i++)
                mem[i] <= '0;
            dout_reg <= '0;
        end
        else begin
            // Update current pointer from next pointer pipeline stage
            ptr_curr <= ptr_next;
            
            // Optimize memory write operations
            for(int i=0; i<N; i++) begin
                if(wr_en[i]) 
                    mem[i] <= din[i*DW +: DW];
            end
            
            // Register the output to break the critical path
            dout_reg <= mem[ptr_curr];
        end
    end
    
    // Output assignment through register
    assign dout = dout_reg;
endmodule